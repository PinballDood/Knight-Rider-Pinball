"""American Pinball PCA9685/PCA9635 LED support for MPF."""

import logging
from mpf.core.platform import LightsPlatform
from mpf.core.platform_batch_light_system import PlatformBatchLightSystem
from mpf.core.platform_batch_light_system import PlatformBatchLight


class APLedChannel(PlatformBatchLight):
    """One PWM channel on an American Pinball LED controller."""

    __slots__ = ["controller", "channel", "platform", "log"]

    def __init__(self, controller, channel, platform, light_system):
        """Initialize an AP LED channel."""
        self.controller = controller
        self.channel = channel
        self.platform = platform

        super().__init__(
            "{}-{}".format(self.controller, self.channel),
            light_system
        )

        self.log = logging.getLogger("APLED")

    def get_max_fade_ms(self):
        """Return maximum supported fade time."""
        return 0

    def get_board_name(self):
        """Return a descriptive controller name."""
        return "AP LED Controller 0x{:02X}".format(self.controller)

    def is_successor_of(self, other):
        """Return whether another channel immediately precedes this one."""
        return (
            isinstance(other, APLedChannel)
            and self.controller == other.controller
            and self.channel == other.channel + 1
        )

    def get_successor_number(self):
        """Return the next channel number."""
        return "{}-{}".format(self.controller, self.channel + 1)

    def __lt__(self, other):
        """Sort channels by controller and channel."""
        return (self.controller, self.channel) < (
            other.controller,
            other.channel
        )


class APLedPlatform(LightsPlatform):
    """American Pinball PCA9685/PCA9635 LED platform."""

    __slots__ = ["p3_roc", "_light_system", "i2c_devices"]

    def __init__(self, machine):
        """Initialize the AP LED platform."""
        super().__init__(machine)

        self.p3_roc = self.machine.hardware_platforms["p3_roc"]
        self.i2c_devices = {}
        self._light_system = PlatformBatchLightSystem(
            self.machine.clock,
            self._send_multiple_light_update,
            self.machine.config["mpf"].get("default_light_hw_update_hz", 50),
            65535
        )
    async def initialize(self):
        """Initialize the American Pinball LED platform."""
        await super().initialize()

    async def start(self):
        """Start the AP LED platform."""
        await super().start()
        self._light_system.start()

    def stop(self):
        """Stop the AP LED platform."""
        self._light_system.stop()
        super().stop()

        # Controllers will be initialized on demand as lights use them.
    async def _get_i2c_device(self, controller):
        """Return an initialized I2C device for an AP LED controller."""

        # Reuse the controller if we have already initialized it.
        if controller in self.i2c_devices:
            return self.i2c_devices[controller]

        # MPF's P3-ROC I2C interface expects the address as a decimal string.
        device = await self.p3_roc.configure_i2c(str(controller))

        # Initialize the PCA9685/PCA9635 exactly as the factory software does.
        device.i2c_write8(0xFD, 0x10)
        device.i2c_write8(0x00, 0x11)
        device.i2c_write8(0xFE, 0x1E)

        device.i2c_write8(0x01, 0x10)
        device.i2c_write8(0x00, 0x01)

        # Remember it so we only initialize each controller once.
        self.i2c_devices[controller] = device

        return device       

    def parse_light_number_to_channels(self, number: str, subtype: str):
        """Convert an AP light address into MPF light channels.

        AP RGB channel order is positional. Preserve the order used
        in the factory configuration rather than reordering R/G/B.
        """
        parts = str(number).upper().split("-")

        if len(parts) < 2 or not parts[0].startswith("A"):
            raise AssertionError(
                "Invalid American Pinball LED address {}".format(number)
            )

        controller = parts[0][1:]
        channels = []

        for part in parts[1:]:
            if len(part) < 2 or part[0] not in ("R", "G", "B"):
                raise AssertionError(
                    "Invalid American Pinball LED address {}".format(number)
                )

            channels.append(int(part[1:]))

        if len(channels) in (1, 3):
            return [
                {"number": "{}-{}".format(controller, channel)}
                for channel in channels
            ]

        raise AssertionError(
            "Unsupported American Pinball LED address {}".format(number)
        )
    def configure_light(self, number, subtype, config, platform_settings):
        """Configure one AP LED hardware channel."""
        controller, channel = number.split("-")

        return APLedChannel(
            int(controller, 16),
            int(channel),
            self,
            self._light_system
        )
    async def _send_multiple_light_update(self, sequential_brightness_list):
        """Send AP LED updates to the hardware."""

        for light, brightness, fade_ms in sequential_brightness_list:
            # Get and initialize the correct AP LED controller.
            device = await self._get_i2c_device(light.controller)

            # Initialize this PWM channel the same way as the factory code.
            device.i2c_write8(
                0x06 + light.channel * 4,
                0x00
            )
            device.i2c_write8(
                0x07 + light.channel * 4,
                0x00
            )

            # Convert MPF's 0.0-1.0 brightness to the factory's 0-255 scale.
            value = int(brightness * 255)

            # Apply the same brightness curve used by the factory software.
            pwm_value = int(value ** 1.5)

            # Write the PWM value.
            device.i2c_write8(
                0x08 + light.channel * 4,
                pwm_value & 0xFF
            )
            device.i2c_write8(
                0x09 + light.channel * 4,
                (pwm_value >> 8) & 0xEF
            )