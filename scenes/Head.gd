extends Spatial

# Misnomer; actually the entire head+camera+gun rotation-y bit

const MOUSE_SENSITIVITY := 2.0 / 1000.0
const Y_LIMIT := deg2rad(90.0)
onready var NORMAL_FOV = $Camera.fov
const ZOOM_FOV_MULTIPLIER = 1.2

var rot := Vector3()
var zoom_factor := 0.0

func _input(event: InputEvent) -> void:
    # Mouse look (only if the mouse is captured).
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        camera_rotation(event.relative)

func _process(delta: float) -> void:
    # Process FOV adjustments
    var min_fov = NORMAL_FOV
    var max_fov = min_fov * ZOOM_FOV_MULTIPLIER
    var target_fov = lerp(min_fov, max_fov, zoom_factor)
    
    $Camera.set_fov(lerp($Camera.fov, target_fov, delta * 8))

func camera_rotation(mouse_axis: Vector2) -> void:
    # Horizontal mouse look.
    rot.y -= mouse_axis.x * MOUSE_SENSITIVITY
    # Vertical mouse look.
    rot.x = clamp(rot.x - mouse_axis.y * MOUSE_SENSITIVITY, -Y_LIMIT, Y_LIMIT)
    
    get_owner().rotation.y = rot.y
    rotation.x = rot.x

func set_zoom_factor(zoom: float) -> void:
    zoom_factor = zoom
    #print(zoom)
