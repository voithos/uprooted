class_name EnemyManager
extends Node


const ENEMY_SCENES := {
    Enemy.SMALL: preload("res://scenes/Enemy.tscn"),
    # TODO: Create other enemy types
    Enemy.MEDIUM: preload("res://scenes/GunnerEnemy.tscn"),
    Enemy.LARGE: preload("res://scenes/Enemy.tscn"),
}

# TODO: Revent before submitting!
#const WAVE_PERIOD := 20.0
const WAVE_PERIOD := 10.0

const STARTING_WAVE_INDEX_FOR_DEBUGGING := 0

# TODO: Test all of this manual and automatic wave-curve configuration.

const EXPLICIT_WAVE_CONFIGS := [
    { small = 1, medium = 0, large = 0 },
    { small = 3, medium = 0, large = 0 },
    { small = 3, medium = 1, large = 0 },
    { small = 3, medium = 0, large = 0 },
    { small = 3, medium = 1, large = 0 }, # Wave 5
    { small = 0, medium = 3, large = 0 },
    { small = 3, medium = 0, large = 0 },
    { small = 3, medium = 2, large = 0 },
    { small = 3, medium = 0, large = 0 },
    { small = 2, medium = 3, large = 0 }, # Wave 10
    { small = 2, medium = 2, large = 0 },
    { small = 5, medium = 0, large = 0 },
    { small = 3, medium = 2, large = 0 },
    { small = 7, medium = 0, large = 0 },
    { small = 2, medium = 3, large = 0 }, # Wave 15
    { small = 0, medium = 4, large = 0 },
    { small = 3, medium = 3, large = 0 },
    { small = 5, medium = 3, large = 0 },
    { small = 4, medium = 3, large = 0 },
    { small = 2, medium = 5, large = 0 }, # Wave 20
    { small = 3, medium = 4, large = 0 },
    { small = 5, medium = 4, large = 0 },
    { small = 4, medium = 4, large = 0 },
    { small = 5, medium = 5, large = 0 },
    { small = 5, medium = 5, large = 0 }, # Wave 25
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

const SPAWN_HEIGHT_OFFSET := 0.5

const SPAWN_POSITION_OFFSET_DIRECTION := Vector3.BACK

const SPAWN_OFFSET_MARGIN := 0.1

var wave_index := STARTING_WAVE_INDEX_FOR_DEBUGGING
var spawn_positions := []
var spawn_position_offset_distances := []

var enemies := {}

var timer: Timer


func _ready() -> void:
    var position_nodes: Array = \
        Session.level.get_node("EnemySpawnPositions").get_children()
    for position in position_nodes:
        spawn_positions.push_back(position.global_translation)
        spawn_position_offset_distances.push_back(0.0)
    
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
        _spawn_enemy(Enemy.SMALL)
    for i in range(medium_count):
        _spawn_enemy(Enemy.MEDIUM)
    # TODO: Large enemies currently disabled
    #for i in range(large_count):
        #_spawn_enemy(Enemy.LARGE)
    
    for i in range(spawn_position_offset_distances.size()):
        spawn_position_offset_distances[i] = 0.0
    
    Session.set_waves_completed(wave_index)
    Session.add_score(_get_wave_score())
    
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


const WAVE_SCORE_BASIS := 50.0


func _get_wave_score() -> int:
    return int(WAVE_SCORE_BASIS * pow(wave_index, WAVE_COUNT_EXPONENT))


func _spawn_enemy(enemy_type: int) -> void:
    var enemy_scene: PackedScene = ENEMY_SCENES[enemy_type]
    var index := min(
        floor(randf() * spawn_positions.size()),
        spawn_positions.size() - 1)
    var spawn_position: Vector3 = spawn_positions[index]
    var spawn_position_offset_distance: float = \
        spawn_position_offset_distances[index]
    spawn_position_offset_distances[index] += \
        Enemy.HALF_WIDTH[enemy_type] + SPAWN_OFFSET_MARGIN
    var offset_delta := \
        SPAWN_POSITION_OFFSET_DIRECTION * spawn_position_offset_distance
    spawn_position += offset_delta
    spawn_position.y = \
        _find_safe_spawn_height(spawn_position, enemy_type) + \
        spawn_position_offset_distance * 0.6
    
    var enemy: Enemy = enemy_scene.instance()
    Session.level.add_child(enemy)
    enemy.global_translation = spawn_position
    enemies[enemy] = true


func _find_safe_spawn_height(
        spawn_position: Vector3,
        enemy_type: int) -> float:
    return Session.level.get_heightmap_height_at_position(spawn_position) + \
        Enemy.HALF_HEIGHT[enemy_type] + \
        SPAWN_HEIGHT_OFFSET


func get_wave_cooldown_progress() -> float:
    return timer.time_left / timer.wait_time


func on_enemy_destroyed(enemy: Enemy) -> void:
    enemies.erase(enemy)
    enemy.queue_free()
    Session.enemies_destroyed += 1
