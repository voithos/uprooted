class_name PoolManager
extends Node


const START_POOL_COUNT := 2.0

var pools := []
var hydrated_pools := {}
var dehydrated_pools := {}


func _ready() -> void:
    var pools: Array = Session.level.get_node("Pools").get_children()
    for pool in pools:
        pool.set_is_hydrated(hydrated_pools.size() < START_POOL_COUNT)
        if pool.is_hydrated:
            hydrated_pools[pool] = true
        else:
            dehydrated_pools[pool] = true
