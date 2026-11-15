extends AnimatedSprite2D

const FRAME_COUNT := 8
const FRAME_FOLDER := "res://assets/kitt_scanner_frames/"

func _ready() -> void:
    var frames := SpriteFrames.new()
    frames.add_animation("scan")
    frames.set_animation_speed("scan", 11.0)
    frames.set_animation_loop("scan", true)

    for i in range(FRAME_COUNT):
        var path := FRAME_FOLDER + "kitt_%02d.png" % i
        var texture := load(path) as Texture2D
        if texture == null:
            push_error("Missing scanner frame: " + path)
            return
        frames.add_frame("scan", texture)

    sprite_frames = frames
    animation = "scan"
    play()
