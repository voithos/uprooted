class_name ShakeableCamera
extends Camera

export var trauma_reduction_rate := 1.0
export var noise: OpenSimplexNoise
export var noise_speed := 50.0

# Max rotation (degrees)
export var max_x := 10.0
export var max_y := 10.0
export var max_z := 5.0

var trauma := 0.0
var time := 0.0

onready var initial_rotation := rotation_degrees as Vector3

func _ready():
    Session.camera = self

func _physics_process(delta):
    time += delta
    trauma = max(trauma - trauma_reduction_rate * delta, 0.0)
    
func _process(delta):
    var intensity = get_shake_intensity()
    rotation_degrees.x = initial_rotation.x + max_x * intensity * get_noise_from_seed(0)
    rotation_degrees.y = initial_rotation.y + max_y * intensity * get_noise_from_seed(1)
    rotation_degrees.z = initial_rotation.z + max_z * intensity * get_noise_from_seed(2)
    
func add_trauma(amt: float):
    trauma = clamp(trauma + amt, 0.0, 1.0)

func set_min_trauma(amt: float):
    trauma = clamp(max(trauma, amt), 0.0, 1.0)
    
func get_shake_intensity() -> float:
    return trauma * trauma
    
func get_noise_from_seed(s: int) -> float:
    noise.seed = s
    return noise.get_noise_1d(time * noise_speed)
