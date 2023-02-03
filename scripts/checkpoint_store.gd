extends Node

# Checkpointing system.
# Remembers checkpoint locations for in-level resets.

# Note, level names must be unique!
var level_checkpoints = {}

func _ready():
    pass

func has_checkpoint() -> bool:
    return level_checkpoints.has(_level_name())

func get_checkpoint():
    assert(has_checkpoint())
    return level_checkpoints[_level_name()]

func set_checkpoint(position: Vector2):
    level_checkpoints[_level_name()] = position

func _level_name():
    return get_tree().get_current_scene().get_name()
