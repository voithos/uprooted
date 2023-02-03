extends Node

# Game timer.

# Note, level names must be unique!
var started = false
var start_time = 0.0

func _ready():
    # Intentionally not persistable.
    pass

func start_if_not_started():
    if !started:
        start_time = OS.get_ticks_msec()
        started = true

# Returns the current game time.
func game_time_formatted():
    var delta = OS.get_ticks_msec() - start_time
    var seconds = floor(delta / 1000.0)
    var minutes = floor(seconds / 60.0)
    var remainder = floor(seconds - minutes * 60.0)
    return "%d:%02d" % [minutes, remainder]
