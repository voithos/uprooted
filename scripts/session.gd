extends Node


var level: Level
var player: Player

var is_level_ready: bool setget ,_get_is_level_ready


func _get_is_level_ready() -> bool:
    return is_instance_valid(level) and level.is_ready
