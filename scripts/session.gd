extends Node

var level: Level
var player: Player
var camera: ShakeableCamera

var is_level_ready: bool setget ,_get_is_level_ready
var is_player_and_level_ready: bool setget ,_get_is_player_and_level_ready

var waves_completed := 0
var enemies_destroyed := 0
var pools_drained := 0
# - Destroying enemies increases score.
# - Surviving waves increases score.
var score := 0


func reset() -> void:
    if is_instance_valid(Session.level):
        Session.level.queue_free()
    level = null
    player = null
    waves_completed = 0
    enemies_destroyed = 0
    pools_drained = 0
    score = 0
    Screen.get_hud().reset()


func add_score(value: int) -> void:
    set_score(score + value)


func set_score(value: int) -> void:
    score = value
    Screen.get_hud().update_score()


func set_waves_completed(value: int) -> void:
    waves_completed = value
    Screen.get_hud().update_waves()


func update_health(value: float) -> void:
    Screen.get_hud().update_health()


func _get_is_level_ready() -> bool:
    return is_instance_valid(level) and level.is_ready


func _get_is_player_and_level_ready() -> bool:
    return is_instance_valid(player) and _get_is_level_ready()
