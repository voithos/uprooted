class_name Player
extends KinematicBody

const GRAVITY_MULT := 3.0
# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
onready var GRAVITY: float = (ProjectSettings.get_setting("physics/3d/default_gravity") 
        * GRAVITY_MULT)

const MIN_DISTANCE_BELOW_SEA_LEVEL := 1.0

const MAX_SPEED := 10.0
const SPRINT_MULTIPLIER := 2.0 # Applied to MAX_SPEED to get sprint speed
const JUMP_SPEED := 18.0
const ACCEL := 10.0
const DECEL := 16.0
const SPRINT_ACCEL_MULTIPLIER := 1.5
# How good movement in midair is.
const AIR_CONTROL := 0.3
const MAX_SLOPE_ANGLE := deg2rad(40.0)
const STOP_ON_SLOPES := true

const JUMP_RELEASE_MULTIPLIER := 0.5 # Multiplied by velocity if button released
const FAST_FALL_MULTIPLIER := 1.7 # How much faster fast fall is compared to gravity

var collision_extents: Vector3

var velocity := Vector3()
var direction := Vector3()
var snap := Vector3()

var previous_position := Vector3.INF
var previous_ground_position := Vector3.INF

const ROOT_DURATION := 0.8
const UNROOT_DURATION := 0.4
var rooting_tween: SceneTreeTween

# Ye olde terrible boolean state machine
var is_rooted := false
var is_rooting := false
var is_unrooting := false

var is_airborne := false
var was_airborne := false
var is_fast_falling := false

const MAX_HEALTH = 6.0
var health = MAX_HEALTH
signal health_changed
var is_invulnerable := false
const INVULNERABILITY_AFTER_DAMAGE = 1.0 # Amount of time after taking damage that you're invulnerable
var invulnerability_timer := 0.0

const DEFAULT_DAMAGE = 1.0  # Damage from basic enemy touch

onready var bullet_spawner = $Head/gun/BulletSpawner
onready var original_head_y = $Head.translation.y

var pool: Pool

func _ready():
    Session.player = self
    
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    collision_extents.x = $CollisionShape.shape.radius
    collision_extents.y = \
        $CollisionShape.shape.height * 0.5 + $CollisionShape.shape.radius
    collision_extents.z = $CollisionShape.shape.radius
    
    previous_position = global_translation

func _physics_process(delta: float) -> void:
    process_movement(delta)
    process_rooting(delta)
    process_firing(delta)
    
    _update_invulnerability(delta)
    
    if Input.is_action_just_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func process_rooting(delta: float) -> void:
    if Input.is_action_just_pressed("root"):
        if !is_rooted and _can_root():
            _begin_rooting()
        elif !is_unrooting:
            # Can always unroot
            _begin_unrooting()

func _is_in_root_state():
    return is_rooted or is_rooting or is_unrooting

func _can_root():
    # TODO: Add more root requirements here
    return !is_airborne and !is_rooting

func _begin_rooting():
    is_rooting = true
    rooting_tween = get_tree().create_tween()
    rooting_tween.tween_property($Head, "translation:y", 0.0, ROOT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
    yield(rooting_tween, "finished")
    is_rooted = true
    is_rooting = false
    rooting_tween = null
    if is_instance_valid(pool):
        pool.set_is_rooted(true)

func _begin_unrooting():
    is_unrooting = true
    # Immediately disengage
    is_rooted = false
    if is_instance_valid(pool):
        pool.set_is_rooted(false)
    # In case we need to override
    var duration := UNROOT_DURATION
    if rooting_tween:
        duration *= rooting_tween.get_total_elapsed_time() / ROOT_DURATION
        rooting_tween.kill()
        rooting_tween = null
    is_rooting = false
    var tween = get_tree().create_tween()
    tween.tween_property($Head, "translation:y", original_head_y, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    yield(tween, "finished")
    
    is_unrooting = false

func process_movement(delta: float) -> void:
    var input_axis = Input.get_vector(
        "move_back",
        "move_forward",
        "move_left",
        "move_right"
    )

    direction = Vector3()
    var aim: Basis = get_global_transform().basis
    # Convert input to 3D direction vector.
    direction = aim.z * -input_axis.x + aim.x * input_axis.y
    
    if _is_in_root_state():
        direction = Vector3()
    
    if is_on_floor():
        is_airborne = false
        # Handle moving platforms.
        snap = -get_floor_normal() - get_floor_velocity() * delta
        
        # Workaround for sliding down after jump on slope
        if velocity.y < 0:
            velocity.y = 0
        
        if Input.is_action_just_pressed("jump"):
            snap = Vector3.ZERO
            velocity.y = JUMP_SPEED
            is_fast_falling = false
    else:
        is_airborne = true
        # Workaround for 'vertical bump' when going off platform
        if snap != Vector3.ZERO && velocity.y != 0:
            velocity.y = 0
        snap = Vector3.ZERO
        
        if Input.is_action_just_released("jump"):
            is_fast_falling = true
            if velocity.y > 0:
                velocity.y *= JUMP_RELEASE_MULTIPLIER
        
        var fall_multiplier = 1.0
        if is_fast_falling:
            fall_multiplier = FAST_FALL_MULTIPLIER

        velocity.y -= GRAVITY * fall_multiplier * delta
    
    accelerate_horizontal(delta)
    
    previous_position = global_translation
    if !is_airborne:
        previous_ground_position = global_translation
    
    velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, 
            STOP_ON_SLOPES, 4, MAX_SLOPE_ANGLE)
    
    var next_foot_position := get_foot_position()
    
    # Prevent the player from walking too far out to sea.
    if next_foot_position.y < -MIN_DISTANCE_BELOW_SEA_LEVEL:
        global_translation = previous_ground_position
    
    was_airborne = is_airborne

func accelerate_horizontal(delta: float) -> void:
    # Using only the horizontal velocity, interpolate towards the input.
    var temp_vel := velocity
    temp_vel.y = 0
    
    var is_sprinting := Input.is_action_pressed("sprint")
    var sprint_multiplier = SPRINT_MULTIPLIER if is_sprinting else 1.0

    var temp_accel: float
    var target_speed = MAX_SPEED * sprint_multiplier
    var target: Vector3 = direction * target_speed
    
    var accel_multiplier = SPRINT_ACCEL_MULTIPLIER if is_sprinting else 1.0
    if direction.dot(temp_vel) > 0:
        temp_accel = ACCEL * accel_multiplier
    else:
        temp_accel = DECEL * accel_multiplier
    
    if is_airborne:
        temp_accel *= AIR_CONTROL
    
    temp_vel = temp_vel.linear_interpolate(target, temp_accel * delta)
    
    velocity.x = temp_vel.x
    velocity.z = temp_vel.z
    
    if is_sprinting:
        var rel = (target / target_speed).dot(velocity / target_speed)
        $Head.set_zoom_factor(rel)
    else:
        $Head.set_zoom_factor(0.0)

func get_foot_position() -> Vector3:
    return global_translation - Vector3(0, collision_extents.y, 0)

func process_firing(delta: float):
    # TODO: make this auto-fire
    if !_can_fire():
        return

    if Input.is_action_just_pressed("fire"):
        bullet_spawner.spawn_bullet()
        pool.consume_water(Pool.SMALL_SHOT_WATER_AMOUNT)

func _can_fire():
    return is_rooted and get_is_near_hydrated_pool()

func _take_damage(damage):
    if is_invulnerable:
        # Hit two things in a single frame; ignore.
        return
    set_health(health - damage)
    _begin_invulernability_after_damage()
    Session.camera.add_trauma(0.8)

func _begin_invulernability_after_damage():
    is_invulnerable = true
    invulnerability_timer = 0.0

func _update_invulnerability(delta):
    if is_invulnerable:
        invulnerability_timer += delta
        if invulnerability_timer > INVULNERABILITY_AFTER_DAMAGE:
            is_invulnerable = false
            call_deferred("_check_for_hitboxes")

func _check_for_hitboxes():
    yield(get_tree(), "idle_frame")
    var hitboxes = $Hurtbox.get_overlapping_areas()
    if len(hitboxes) > 0:
        _take_damage(DEFAULT_DAMAGE)

func set_health(h):
    health = min(max(0, h), MAX_HEALTH)
    emit_signal("health_changed", health, MAX_HEALTH)
    if health <= 0:
        die()

func _on_Hurtbox_body_entered(body):
    _take_damage(DEFAULT_DAMAGE)

func _on_Hurtbox_area_entered(area):
    _take_damage(DEFAULT_DAMAGE)

func die():
    queue_free()

    #yield(get_tree().create_timer(1.0), "timeout")
    
    #var level = get_tree().get_nodes_in_group("level")[0]
    #level.begin_reset_transition()

func set_is_near_pool(is_near_pool: bool, value: Pool) -> void:
    var was_near_hydrated_pool := get_is_near_hydrated_pool()
    if is_near_pool:
        pool = value
    else:
        if pool == value:
            pool = null
    if get_is_near_hydrated_pool() != was_near_hydrated_pool:
        on_is_near_hydrated_pool_changed()

func get_is_near_hydrated_pool() -> bool:
    return is_instance_valid(pool) and pool.is_hydrated

func on_is_near_hydrated_pool_changed() -> void:
    # TODO: Update UI?
    pass
