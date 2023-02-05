class_name PoolManager
extends Node


const START_POOL_COUNT := 2

var pools := []
var hydrated_pools := {}
var dehydrated_pools := {}


func _ready() -> void:
    pools = Session.level.get_node("Pools").get_children()


func on_player_ready() -> void:
    for pool in pools:
        pool.on_player_ready()
