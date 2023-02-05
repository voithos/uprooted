extends Node

var level: Level
var player: Player
var camera: ShakeableCamera

var is_level_ready: bool setget ,_get_is_level_ready
var is_player_and_level_ready: bool setget ,_get_is_player_and_level_ready

var waves_completed := 0
var enemies_destroyed := 0
var pools_drained := 0


func reset() -> void:
    level = null
    player = null
    waves_completed = 0
    enemies_destroyed = 0
    pools_drained = 0


func _get_is_level_ready() -> bool:
    return is_instance_valid(level) and level.is_ready


func _get_is_player_and_level_ready() -> bool:
    return is_instance_valid(player) and _get_is_level_ready()
