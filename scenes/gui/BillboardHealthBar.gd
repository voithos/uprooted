tool
class_name BillboardHealthBar
extends MeshInstance


export var full_color := Color("44ff00")
export var empty_color := Color("ff0000")
export var background_color := Color("100d2b")
export var size := Vector2(1.6, 0.2)

var material: ShaderMaterial


func _ready() -> void:
    # Make unique.
    mesh = mesh.duplicate()
    mesh.material = mesh.material.duplicate()
    material = mesh.material
    
    material.set_shader_param("albedo_to", full_color)
    material.set_shader_param("albedo_from", empty_color)
    material.set_shader_param("albedo_bg", background_color)


func set_progress(progress: float) -> void:
    material.set_shader_param("progress", progress)


func set_full_color(value: Color) -> void:
    full_color = value
    material.set_shader_param("albedo_to", full_color)


func set_empty_color(value: Color) -> void:
    empty_color = value
    material.set_shader_param("albedo_from", empty_color)


func set_background_color(value: Color) -> void:
    background_color = value
    material.set_shader_param("albedo_bg", background_color)
