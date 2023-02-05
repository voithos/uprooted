tool
class_name Pool
extends Spatial


const DOES_CONSUMING_WATER_DRAIN_POOL := false
const DOES_POOL_HYDRATION_TOGGLE_ON_DELAY := true

const DEFAULT_MAX_WATER_LEVEL := 27.0
const DEFAULT_MIN_REHYDRATION_DELAY := 10.0
const DEFAULT_MAX_REHYDRATION_DELAY := 30.0
const DEFAULT_MIN_DEHYDRATION_DELAY := 10.0
const DEFAULT_MAX_DEHYDRATION_DELAY := 30.0

const SMALL_SHOT_WATER_AMOUNT := 1.0
const MEDIUM_SHOT_WATER_AMOUNT := 3.0
const LARGE_SHOT_WATER_AMOUNT := 9.0

const _REHYDRATION_FADE_DURATION := 1.0
const _DEHYDRATION_FADE_DURATION := 3.0

const _BASE_SCALE := 5.0

export var max_water_level := DEFAULT_MAX_WATER_LEVEL
export var min_rehydration_delay := DEFAULT_MIN_REHYDRATION_DELAY
export var max_rehydration_delay := DEFAULT_MAX_REHYDRATION_DELAY
export var min_dehydration_delay := DEFAULT_MIN_DEHYDRATION_DELAY
export var max_dehydration_delay := DEFAULT_MAX_DEHYDRATION_DELAY
export var horizontal_scale := 1.0

var is_hydrated := false
var last_hydration_time := -1.0
var last_dehydration_time := -1.0
var water_level := 0.0
var is_rooted := false

var timer: Timer
var tween: Tween


func _ready() -> void:
    timer = Timer.new()
    timer.one_shot = true
    timer.autostart = false
    timer.wait_time = min_rehydration_delay
    timer.connect("timeout", self, "_toggle_hydration")
    add_child(timer)
    
    tween = Tween.new()
    tween.connect("tween_completed", self, "_on_tween_completed")
    add_child(tween)
    
    var scale_value := _BASE_SCALE * horizontal_scale
    $Meshes.scale.x = scale_value
    $Meshes.scale.z = scale_value
    $Area/CollisionShape.shape.radius = scale_value
    var material: ParticlesMaterial = $Particles.process_material
    material.emission_ring_radius = scale_value
    material.emission_ring_inner_radius = scale_value * 0.95
    
    call_deferred("_sanitize_position")


func on_player_ready() -> void:
    var starts_hydrated: bool = \
        Session.level.pool_manager.hydrated_pools.size() < \
        PoolManager.START_POOL_COUNT
    set_is_hydrated(starts_hydrated)


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
    
    var terrain: Terrain = Session.level.terrain
    var heightmap_cell_position: Vector3 = terrain.world_to_map(from)
#    var heightmap_image: Image = terrain._data.get_image(HTerrainData.CHANNEL_HEIGHT)
#    var height: float = terrain._get_height_or_default(image, heightmap_cell_position.x, heightmap_cell_position.z)
    var height: float = terrain._data.get_height_at(heightmap_cell_position.x, heightmap_cell_position.z)
    
    global_translation.y = height


func _toggle_hydration() -> void:
    set_is_hydrated(!is_hydrated)


func set_is_hydrated(value: bool) -> void:
    if !Session.is_player_and_level_ready:
        return
    
    is_hydrated = value
    timer.stop()
    $Particles.emitting = is_hydrated and !is_rooted
    
    var was_player_near_hydrated_pool: bool = \
        Session.player.get_is_near_hydrated_pool()
    
    if is_hydrated:
        last_hydration_time = OS.get_ticks_msec()
        water_level = max_water_level
        Session.level.pool_manager.dehydrated_pools.erase(self)
        Session.level.pool_manager.hydrated_pools[self] = true
        timer.wait_time = \
            rand_range(min_dehydration_delay, max_dehydration_delay)
        timer.start()
    else:
        last_dehydration_time = OS.get_ticks_msec()
        water_level = 0.0
        Session.level.pool_manager.dehydrated_pools[self] = true
        Session.level.pool_manager.hydrated_pools.erase(self)
        timer.wait_time = \
            rand_range(min_rehydration_delay, max_rehydration_delay)
        timer.start()
    
    if Session.player.get_is_near_hydrated_pool() != \
            was_player_near_hydrated_pool:
        Session.player.on_is_near_hydrated_pool_changed()
    
    # Fade in/out.
    var water_image: SpatialMaterial = \
        $Meshes/WaterImage.get_active_material(0)
    var start := water_image.albedo_color.a
    var end: float
    var duration: float
    var ease_type: int
    if is_hydrated:
        end = 1.0
        duration = _REHYDRATION_FADE_DURATION
        ease_type = Tween.EASE_OUT
    else:
        end = 0.0
        duration = _DEHYDRATION_FADE_DURATION
        ease_type = Tween.EASE_IN
    tween.stop_all()
    tween.interpolate_property(
        water_image,
        "albedo_color:a",
        start,
        end,
        duration,
        Tween.TRANS_QUAD,
        ease_type,
        0.0)
    tween.start()


func set_is_rooted(value) -> void:
    is_rooted = value
    $Particles.emitting = is_hydrated and !is_rooted


func _on_tween_completed(object: Object, key: NodePath) -> void:
    if is_hydrated:
        object.albedo_color.a = 1.0 if is_hydrated else 0.0


func consume_water(amount: float) -> void:
    water_level -= amount
    if water_level <= 0.0 and DOES_CONSUMING_WATER_DRAIN_POOL:
        set_is_hydrated(false)
        Session.pools_drained += 1


func _on_Area_body_entered(body):
    if body == Session.player:
        Session.player.set_is_near_pool(true, self)


func _on_Area_body_exited(body):
    if body == Session.player:
        Session.player.set_is_near_pool(false, self)
