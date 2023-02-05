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

const _DEHYDRATION_MIN_RADIUS_RATIO := 0.2

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
var _next_hydration_toggle_time := INF

var material: ShaderMaterial
var tween: Tween


func _ready() -> void:
    tween = Tween.new()
    tween.connect("tween_completed", self, "_on_tween_completed")
    add_child(tween)
    
    var scale_value := _BASE_SCALE * horizontal_scale
    $Dynamic.scale = Vector3.ONE * scale_value
    $Area/CollisionShape.shape.radius = scale_value
    var particles: ParticlesMaterial = $Particles.process_material
    particles.emission_ring_radius = scale_value
    particles.emission_ring_inner_radius = scale_value * 0.95
    
    # Make material unique.
    material = $Dynamic/Ripples.mesh.material.duplicate()
    $Dynamic/Ripples.mesh.material = material
    
    call_deferred("_sanitize_position")


func _process(delta: float) -> void:
    if OS.get_ticks_msec() > _next_hydration_toggle_time:
        _toggle_hydration()


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
    _clear_timeout()
    $Particles.emitting = is_hydrated and !is_rooted
    $Dynamic/Bubbles.emitting = is_hydrated
    
    var was_player_near_hydrated_pool: bool = \
        Session.player.get_is_near_hydrated_pool()
    
    var hydration_delay: float
    if is_hydrated:
        last_hydration_time = OS.get_ticks_msec()
        water_level = max_water_level
        Session.level.pool_manager.dehydrated_pools.erase(self)
        Session.level.pool_manager.hydrated_pools[self] = true
        hydration_delay = \
            rand_range(min_dehydration_delay, max_dehydration_delay)
    else:
        last_dehydration_time = OS.get_ticks_msec()
        water_level = 0.0
        Session.level.pool_manager.dehydrated_pools[self] = true
        Session.level.pool_manager.hydrated_pools.erase(self)
        hydration_delay = \
            rand_range(min_rehydration_delay, max_rehydration_delay)
    
    if Session.player.get_is_near_hydrated_pool() != \
            was_player_near_hydrated_pool:
        Session.player.on_is_near_hydrated_pool_changed()
    
    # Fade in/out.
    var start: float
    var end: float
    var duration: float
    var ease_type: int
    if is_hydrated:
        start = 0.0
        end = 1.0
        duration = _REHYDRATION_FADE_DURATION
        ease_type = Tween.EASE_OUT
    else:
        start = 1.0
        end = 0.0
        duration = _DEHYDRATION_FADE_DURATION
        ease_type = Tween.EASE_IN
    
    tween.stop_all()
    _interpolate_hydration(start)
    tween.interpolate_method(
        self,
        "_interpolate_hydration",
        start,
        end,
        duration,
        Tween.TRANS_QUAD,
        ease_type,
        0.0)
    
    tween.start()
    _set_timeout(hydration_delay)


func set_is_rooted(value) -> void:
    is_rooted = value
    $Particles.emitting = is_hydrated and !is_rooted


func _interpolate_hydration(progress: float) -> void:
    material.set_shader_param("alpha_multiplier", progress)
    
    $Dynamic/Ripples.scale = \
        lerp(_DEHYDRATION_MIN_RADIUS_RATIO, 1.0, progress) * Vector3.ONE


func _on_tween_completed(object: Object, key: NodePath) -> void:
    _interpolate_hydration(1.0 if is_hydrated else 0.0)


func _set_timeout(delay: float) -> void:
    _next_hydration_toggle_time = OS.get_ticks_msec() + delay * 1000.0


func _clear_timeout() -> void:
    _next_hydration_toggle_time = INF


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
