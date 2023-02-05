tool
class_name Box
extends MeshInstance


export var size := Vector3.ONE setget _set_size

var cube_mesh: CubeMesh
var box_shape: BoxShape

var is_ready := false


func _ready() -> void:
    is_ready = true
    
    cube_mesh = self.mesh.duplicate()
    self.mesh = cube_mesh
    
    box_shape = $StaticBody/CollisionShape.shape.duplicate()
    $StaticBody/CollisionShape.shape = box_shape
    
    _set_size(size)


func _set_size(value: Vector3) -> void:
    size = value
    if !is_ready:
        return
    cube_mesh.size = size
    box_shape.extents = size / 2
