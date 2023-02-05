class_name Pool
extends Spatial


const DEFAULT_MAX_WATER_LEVEL := 27.0
const DEFAULT_MIN_REHYDRATION_PERIOD := 60.0
const DEFAULT_MAX_REHYDRATION_PERIOD := 240.0

const SMALL_SHOT_WATER_AMOUNT := 1.0
const MEDIUM_SHOT_WATER_AMOUNT := 3.0
const LARGE_SHOT_WATER_AMOUNT := 9.0

var max_water_level := DEFAULT_MAX_WATER_LEVEL
var min_rehydration_period := DEFAULT_MIN_REHYDRATION_PERIOD
var max_rehydration_period := DEFAULT_MAX_REHYDRATION_PERIOD

var is_hydrated := false
var last_hydration_time := -1.0
var last_dehydration_time := -1.0
var water_level := 0.0

var timer: Timer


func _ready() -> void:
    timer = Timer.new()
    timer.one_shot = true
    timer.autostart = false
    timer.wait_time = min_rehydration_period
    timer.connect("timeout", self, "_rehydrate")
    add_child(timer)
    
    call_deferred("_sanitize_position")


func _sanitize_position() -> void:
    var from := global_translation
    from.y = 1000.0
#    var to := global_translation
#    to.y = 0.0
#    var exclude := []
#    var collision_mask := Global.WORLD_COLLISION_MASK
#    var collide_with_bodies := true
#    var collide_with_areas := false
#    var space_state := get_world().direct_space_state
#    var result := space_state.intersect_ray(
#        from,
#        to,
#        exclude,
#        collision_mask,
#        collide_with_bodies)
#    global_translation = result.position
    
#    var direction := Vector3.DOWN
#    var max_distance := 1000.0
#    global_translation = \
#        Session.level.terrain.cell_raycast(from, direction, max_distance)
    
    var terrain := Session.level.terrain
    var heightmap_cell_position: Vector3 = terrain.world_to_map(from)
#    var heightmap_image: Image = terrain._data.get_image(HTerrainData.CHANNEL_HEIGHT)
#    var height: float = terrain._get_height_or_default(image, heightmap_cell_position.x, heightmap_cell_position.z)
    var height: float = terrain._data.get_height_at(heightmap_cell_position.x, heightmap_cell_position.z)
    
    global_translation.y = height


func _rehydrate() -> void:
    set_is_hydrated(true)


func set_is_hydrated(is_hydrated: bool) -> void:
    self.is_hydrated = is_hydrated
    timer.stop()
    if is_hydrated:
        last_hydration_time = OS.get_ticks_msec()
        water_level = max_water_level
        Session.level.pool_manager.dehydrated_pools.erase(self)
        Session.level.pool_manager.hydrated_pools[self] = true
    else:
        last_dehydration_time = OS.get_ticks_msec()
        water_level = 0.0
        Session.level.pool_manager.dehydrated_pools[self] = true
        Session.level.pool_manager.hydrated_pools.erase(self)
        timer.wait_time = \
            rand_range(min_rehydration_period, max_rehydration_period)
        timer.start()


func consume_water(amount: float) -> void:
    water_level -= amount
    if water_level <= 0.0:
        set_is_hydrated(false)
        Session.pools_drained += 1
