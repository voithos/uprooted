extends Spatial

const MOUSE_SENSITIVITY := 2.0 / 1000.0
const Y_LIMIT := deg2rad(90.0)
var rot := Vector3()

func _input(event: InputEvent) -> void:
    # Mouse look (only if the mouse is captured).
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        camera_rotation(event.relative)

func camera_rotation(mouse_axis: Vector2) -> void:
    # Horizontal mouse look.
    rot.y -= mouse_axis.x * MOUSE_SENSITIVITY
    # Vertical mouse look.
    rot.x = clamp(rot.x - mouse_axis.y * MOUSE_SENSITIVITY, -Y_LIMIT, Y_LIMIT)
    
    get_owner().rotation.y = rot.y
    rotation.x = rot.x
