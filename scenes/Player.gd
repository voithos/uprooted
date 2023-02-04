extends KinematicBody

const GRAVITY_MULT := 3.0
# Get the gravity from the project settings to be synced with RigidDynamicBody nodes.
onready var GRAVITY = (ProjectSettings.get_setting("physics/3d/default_gravity") 
        * GRAVITY_MULT)

const MAX_SPEED = 20
const JUMP_SPEED = 18
const ACCEL = 4.5
const DECEL = 16
# How good movement in midair is.
const AIR_CONTROL := 0.3
const MAX_SLOPE_ANGLE = 40
const STOP_ON_SLOPES = true

var velocity := Vector3()
var direction := Vector3()
var snap := Vector3()

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
    process_movement(delta)
    
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
        # Handle moving platforms.
        snap = -get_floor_normal() - get_floor_velocity() * delta
        
        # Workaround for sliding down after jump on slope
        if velocity.y < 0:
            velocity.y = 0
        
        if Input.is_action_just_pressed("jump"):
            snap = Vector3.ZERO
            velocity.y = JUMP_SPEED
    else:
        # Workaround for 'vertical bump' when going off platform
        if snap != Vector3.ZERO && velocity.y != 0:
            velocity.y = 0
        
        snap = Vector3.ZERO
        
        velocity.y -= GRAVITY * delta
    
    accelerate(delta)
    
    velocity = move_and_slide_with_snap(velocity, snap, Vector3.UP, 
            STOP_ON_SLOPES, 4, MAX_SLOPE_ANGLE)

func accelerate(delta: float) -> void:
    # Using only the horizontal velocity, interpolate towards the input.
    var temp_vel := velocity
    temp_vel.y = 0
    
    var temp_accel: float
    var target: Vector3 = direction * MAX_SPEED
    
    if direction.dot(temp_vel) > 0:
        temp_accel = ACCEL
    else:
        temp_accel = DECEL
    
    if not is_on_floor():
        temp_accel *= AIR_CONTROL
    
    temp_vel = temp_vel.linear_interpolate(target, temp_accel * delta)
    
    velocity.x = temp_vel.x
    velocity.z = temp_vel.z

