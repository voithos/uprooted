tool
class_name BillboardHealthBar
extends MeshInstance


export var full_color := Color("44ff00")
export var empty_color := Color("ff0000")
export var backgroundS_color := Color("100d2b")
export var size := Vector2(1.6, 0.2)

var material: ShaderMaterial


func _ready() -> void:
    # Make unique.
    mesh = mesh.duplicate()
    mesh.material = mesh.material.duplicate()
    material = mesh.material
    
    material.set_shader_param("albedo_to", full_color)
    material.set_shader_param("albedo_from", empty_color)
    material.set_shader_param("albedo_bg", backgroundS_color)


func set_progress(progress: float) -> void:
    material.set_shader_param("progress", progress)
