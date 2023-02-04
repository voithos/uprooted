extends KinematicBody

const GRAVITY_MULT := 3.0
# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
onready var GRAVITY: float = (ProjectSettings.get_setting("physics/3d/default_gravity") 
        * GRAVITY_MULT)

const MIN_DISTANCE_BELOW_SEA_LEVEL := 1.0

const MAX_SPEED := 5.0
const SPRINT_MULTIPLIER := 2.0 # Applied to MAX_SPEED to get sprint speed
const JUMP_SPEED := 18.0
const ACCEL := 4.5
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

# Ye olde terrible boolean state machine
var is_airborne := false
var was_airborne := false
var is_fast_falling := false

onready var bullet_spawner = $Head/BulletSpawner

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    collision_extents.x = $CollisionShape.shape.radius
    collision_extents.y = \
        $CollisionShape.shape.height * 0.5 + $CollisionShape.shape.radius
    collision_extents.z = $CollisionShape.shape.radius
    
    previous_position = global_translation

func _physics_process(delta: float) -> void:
    process_movement(delta)
    process_firing(delta)
    
    if Input.is_action_just_pressed("ui_cancel"):
        if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

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
    if Input.is_action_just_pressed("fire"):
        bullet_spawner.spawn_bullet()
