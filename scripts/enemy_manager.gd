class_name EnemyManager
extends Node


const SMALL_ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
# TODO: Create other enemy types
const MEDIUM_ENEMY_SCENE := preload("res://scenes/Enemy.tscn")
const LARGE_ENEMY_SCENE := preload("res://scenes/Enemy.tscn")

const STARTING_WAVE_INDEX_FOR_DEBUGGING := 0

# TODO: Test all of this manual and automatic wave-curve configuration.

const EXPLICIT_WAVE_CONFIGS := [
    { small = 1, medium = 0, large = 0 },
    { small = 3, medium = 0, large = 0 },
    { small = 0, medium = 1, large = 0 },
    { small = 3, medium = 0, large = 0 },
    { small = 3, medium = 1, large = 0 }, # Wave 5
    { small = 0, medium = 0, large = 1 },
    { small = 3, medium = 0, large = 0 },
    { small = 3, medium = 2, large = 0 },
    { small = 3, medium = 0, large = 0 },
    { small = 2, medium = 1, large = 1 }, # Wave 10
]

const SMALL_ENEMY_HEAVY_WAVE_PERIOD := 2
const MEDIUM_ENEMY_HEAVY_WAVE_PERIOD := 3
const LARGE_ENEMY_HEAVY_WAVE_PERIOD := 5

const SMALL_ENEMY_HEAVY_WAVE_OFFSET := 0
const MEDIUM_ENEMY_HEAVY_WAVE_OFFSET := 0
const LARGE_ENEMY_HEAVY_WAVE_OFFSET := 0

const SMALL_ENEMY_COUNT_BASIS := 1
const MEDIUM_ENEMY_COUNT_BASIS := 0.5
const LARGE_ENEMY_COUNT_BASIS := 0.15

const HEAVY_WAVE_MULTIPLIER := 1.5

const WAVE_COUNT_EXPONENT := 0.8

const WAVE_PERIOD := 20.0

var wave_index := STARTING_WAVE_INDEX_FOR_DEBUGGING
var spawn_positions := []

var enemies := {}

var timer: Timer


func _ready() -> void:
    var position_nodes: Array = \
        Session.level.get_node("EnemySpawnPositions").get_children()
    for position in position_nodes:
        spawn_positions.push_back(position.global_translation)
    
    timer = Timer.new()
    timer.one_shot = false
    timer.autostart = true
    timer.wait_time = WAVE_PERIOD
    timer.connect("timeout", self, "_spawn_next_wave")
    add_child(timer)
    
    _spawn_next_wave()


func _spawn_next_wave() -> void:
    var small_count: int
    var medium_count: int
    var large_count: int
    if wave_index < EXPLICIT_WAVE_CONFIGS.size():
        var config: Dictionary = EXPLICIT_WAVE_CONFIGS[wave_index]
        small_count = config.small
        medium_count = config.medium
        large_count = config.large
    else:
        small_count = _get_enemy_count(
            SMALL_ENEMY_COUNT_BASIS,
            SMALL_ENEMY_HEAVY_WAVE_PERIOD,
            SMALL_ENEMY_HEAVY_WAVE_OFFSET)
        medium_count = _get_enemy_count(
            MEDIUM_ENEMY_COUNT_BASIS,
            MEDIUM_ENEMY_HEAVY_WAVE_PERIOD,
            MEDIUM_ENEMY_HEAVY_WAVE_OFFSET)
        large_count = _get_enemy_count(
            LARGE_ENEMY_COUNT_BASIS,
            LARGE_ENEMY_HEAVY_WAVE_PERIOD,
            LARGE_ENEMY_HEAVY_WAVE_OFFSET)
    
    for i in range(small_count):
        _spawn_enemy(SMALL_ENEMY_SCENE)
    for i in range(medium_count):
        _spawn_enemy(MEDIUM_ENEMY_SCENE)
    for i in range(large_count):
        _spawn_enemy(LARGE_ENEMY_SCENE)
    
    Session.waves_completed = wave_index
    
    wave_index += 1


func _get_enemy_count(
        count_basis: float,
        heavy_wave_period: int,
        heavy_wave_offset: int) -> int:
    var is_heavy_wave := \
        (wave_index - heavy_wave_offset) % \
        heavy_wave_period == 0
    var base := wave_index
    if is_heavy_wave:
        base *= HEAVY_WAVE_MULTIPLIER
    return int(count_basis * pow(base, WAVE_COUNT_EXPONENT))


func _spawn_enemy(enemy_scene: PackedScene) -> void:
    var index := min(
        floor(randf() * spawn_positions.size()),
        spawn_positions.size() - 1)
    var spawn_position: Vector3 = spawn_positions[index]
    spawn_position.y = _find_safe_spawn_height()
    
    var enemy: Enemy = enemy_scene.instance()
    enemy.global_translation = spawn_position
    enemies[enemy] = true
    Session.level.add_child(enemy)


func _find_safe_spawn_height() -> float:
    # TODO: LEFT OFF HERE: Shape-cast to determine y-index
#    var space_state := get_world().direct_space_state
#    var from := global_translation
#    from.y = 1000.0
#    var to := global_translation
#    to.y = 0.0
#    var exclude := []
#    var collision_mask := Global.COLLIDABLE_COLLISION_MASK
#    var collide_with_bodies := true
#    var collide_with_areas := false
#    var result := space_state.intersect_ray(
#        from,
#        to,
#        exclude,
#        collision_mask,
#        collide_with_bodies)
#    var result := space_state.intersect_shape(...)
    return 50.0


func on_enemy_destroyed(enemy: Enemy) -> void:
    enemies.erase(enemy)
    enemy.queue_free()
    Session.enemies_destroyed += 1
