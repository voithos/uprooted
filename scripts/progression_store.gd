extends Node

# Store for storing the state of level completions.

# Note, level names must be unique!
var levels = {}

func _ready():
    add_to_group("persistable")

func has_completed_level(level_id) -> bool:
    return levels.has(level_id)

func complete_current_level():
    levels[_level_name()] = true
    # Persist the data.
    Saving.save_game()

func _level_name():
    return get_tree().get_current_scene().get_name()

func save_state():
    return levels

func load_state(save_data):
    levels = save_data
