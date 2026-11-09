extends MPFSlide

# Knight Rider attract v4 (1366x768). F11 toggles fullscreen, SPACE restarts, H toggles scores.
# Video is persistent under every title/high-score slide, rather than being stopped.
const LENGTH := 90.0
const CUES := [0.0, 6.0, 36.0, 46.0, 58.0, 76.0]
const CUE_NAMES := ["intro", "video", "diagnostics", "title", "scores", "standby"]
const VIDEO_PATH := "res://assets/video/knight_rider_intro.ogv"
const BRIDGE_ENABLED := false # No receiver/MPF bridge is included yet.
const BRIDGE_HOST := "127.0.0.1"
const BRIDGE_PORT := 50505

var elapsed := 0.0
var current_cue := -1
var udp := PacketPeerUDP.new()
var video: VideoStreamPlayer
var shade: ColorRect
var title_label: Label
var sub_label: Label
var ticker: Label
var scanner: ColorRect
var scores_enabled := true
var video_available := false
var leaderboard := ["AAA   12,500,000", "KTT   10,000,000", "MIC    8,500,000", "DEV    6,000,000", "GRT    4,500,000"]
var last_game := ["PLAYER 1   2,450,000", "PLAYER 2   1,225,000"]

func _ready() -> void:
  _build_ui()
  if BRIDGE_ENABLED:
    udp.set_dest_address(BRIDGE_HOST, BRIDGE_PORT)
  _start_loop()

func _build_ui() -> void:
  video = $Video
  shade = $Shade
  title_label = $Title
  sub_label = $Subtitle
  ticker = $Ticker
  scanner = $Scanner

  if not video.finished.is_connected(_on_video_finished):
    video.finished.connect(_on_video_finished)

  # A stream selected in the Inspector takes precedence.
  if video.stream == null and ResourceLoader.exists(VIDEO_PATH):
    video.stream = load(VIDEO_PATH)

  video_available = video.stream != null

  if not video_available:
    push_warning(
			"No attract video. Select Video and assign its Stream, "
      + "or check VIDEO_PATH: " + VIDEO_PATH
    )



func _start_loop() -> void:
  elapsed = 0.0
  current_cue = -1
  if video_available:
    video.stop()
    video.play()
  _enter_cue(0)

func _on_video_finished() -> void:
  # Video is a persistent moving background, including on score screens.
  if video_available:
    video.play()

func _process(delta: float) -> void:
  elapsed += delta
  if elapsed >= LENGTH:
    _start_loop()
    return
  var idx := 0
  for i in range(CUES.size()):
    if elapsed >= CUES[i]:
      idx = i
  if idx != current_cue:
    _enter_cue(idx)
  var phase := elapsed * 2.4
  scanner.modulate.a = 0.6 + 0.4 * absf(sin(phase))
  # Horizontal marquee is positioned in local viewport coordinates.
  ticker.position.x = size.x * 0.04 - fmod(elapsed * size.x * 0.075, size.x * 0.23)

func _enter_cue(idx: int) -> void:
  current_cue = idx
  var cue: String = CUE_NAMES[idx]
  if BRIDGE_ENABLED:
    udp.put_packet(JSON.stringify({"event": "kr_attract_" + cue}).to_utf8_buffer())
  title_label.visible = true
  sub_label.visible = true
  scanner.visible = true
  # Darken moving footage for readability, but never replace it with black.
  shade.color = Color(0.0, 0.0, 0.01, 0.42)
  match cue:
    "intro":
      title_label.text = "FLIPOUT PINBALL"
      sub_label.text = "P R E S E N T S"
      ticker.text = "KNIGHT INDUSTRIES  |  SYSTEMS ONLINE  |  KITT READY"
    "video":
      title_label.text = ""
      sub_label.text = ""
      shade.color = Color(0, 0, 0, 0.04)
      scanner.visible = false
      ticker.text = ""
    "diagnostics":
      title_label.text = "K.I.T.T."
      sub_label.text = "KNIGHT INDUSTRIES TWO THOUSAND\nSYSTEM CHECK: COMPLETE\nSCANNER: ONLINE\nMISSION CONTROL: READY"
      ticker.text = "ALL SYSTEMS NOMINAL  |  AWAITING DRIVER"
    "title":
      title_label.text = "KNIGHT RIDER PINBALL"
      sub_label.text = "ONE MAN. ONE MACHINE. ONE EXTRAORDINARY MISSION."
      ticker.text = "FLIPOUT PINBALL PRESENTS  |  KNIGHT RIDER"
    "scores":
      title_label.text = "HALL OF FAME"
      sub_label.text = "HIGH SCORES\n" + "\n".join(leaderboard) + "\n\nLAST GAME\n" + "\n".join(last_game) if scores_enabled else "SCORES UNAVAILABLE"
      ticker.text = "CAN YOU BEAT THE CHAMPION?"
      shade.color = Color(0, 0, 0.015, 0.68)
    "standby":
      title_label.text = "K.I.T.T. STANDBY"
      sub_label.text = "PRESS START TO ACTIVATE KITT"
      ticker.text = "AWAITING NEXT MISSION  |  KNIGHT INDUSTRIES"

func _unhandled_key_input(event: InputEvent) -> void:
  if event is InputEventKey and event.pressed and not event.echo:
    match event.keycode:
      KEY_SPACE:
        _start_loop()
      KEY_H:
        scores_enabled = not scores_enabled
        _enter_cue(current_cue)
      KEY_F11:
        if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
          DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        else:
          DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
