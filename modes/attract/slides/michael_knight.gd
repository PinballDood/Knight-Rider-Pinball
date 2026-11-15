extends AnimatedSprite2D

const FRAME_COUNT := 6
const FRAME_RATE := 5.5
const FRAME_FOLDER := "res://assets/michael_knight/"

func _ready() -> void:
    var frames := SpriteFrames.new()
    frames.add_animation("thumbs_up")
    frames.set_animation_speed("thumbs_up", FRAME_RATE)
    frames.set_animation_loop("thumbs_up", false)

    for i in range(FRAME_COUNT):
        var path := FRAME_FOLDER + "michael_%02d.png" % i
        var texture := load(path) as Texture2D
        if texture == null:
            push_error("Missing Michael Knight frame: " + path)
            return
        frames.add_frame("thumbs_up", texture)

    sprite_frames = frames
    animation = "thumbs_up"
    frame = 0
    play()
