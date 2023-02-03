extends Node

var is_paused = false

func _ready():
    set_pause_mode(PAUSE_MODE_PROCESS) # Never pause this node.
    if not OS.is_debug_build():
        OS.set_window_fullscreen(true)


func _input(event):
    if event is InputEventKey and event.is_pressed():
        if event.scancode == KEY_ESCAPE and not OS.has_feature("HTML5"):
            # Quitting doesn't make sense for web.
            get_tree().quit()
        if event.scancode == KEY_F11:
            OS.window_fullscreen = not OS.window_fullscreen

        if OS.is_debug_build():
            if event.scancode == KEY_P:
                is_paused = not is_paused
                get_tree().set_pause(is_paused)
