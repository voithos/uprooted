tool
extends MultiMeshInstance

export var extents := Vector2.ONE
export var spawn_outside_circle := false
export var radius := 12.0
export var character_path := NodePath()
export var snap_to_terrain := false
export var num_blades := 4096

var _character: Spatial

func _enter_tree() -> void:
    connect("visibility_changed", self, "_on_WindGrass_visibility_changed")


func _ready() -> void:
    call_deferred("_setup_multimesh")
    
func _setup_multimesh() -> void:
    if character_path:
        _character = get_node(character_path)
    multimesh.instance_count = num_blades
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var theta := 0
    var increase := 1
    var center: Vector3 = get_parent().global_transform.origin

    for instance_index in multimesh.instance_count:
        var transform := Transform().rotated(Vector3.UP, rng.randf_range(-PI / 2, PI / 2))
        var x: float
        var z: float
        if spawn_outside_circle:
            x = center.x + (radius + rng.randf_range(0, extents.x)) * cos(theta)
            z = center.z + (radius + rng.randf_range(0, extents.y)) * sin(theta)
            theta += increase
        else:
            x = rng.randf_range(-extents.x, extents.x)
            z = rng.randf_range(-extents.y, extents.y)
            
        transform.origin = Vector3(x, 0, z)
        
        # Only snap in-game because autoloads aren't available in editor.
        if snap_to_terrain and !Engine.editor_hint:
            var from := global_translation + transform.origin
            from.y = 1000.0
            var terrain: Terrain = Session.level.terrain
            var heightmap_cell_position: Vector3 = terrain.world_to_map(from)
            var height: float = terrain._data.get_height_at(heightmap_cell_position.x, heightmap_cell_position.z)    
            transform.origin.y = height - global_transform.origin.y

        multimesh.set_instance_transform(instance_index, transform)


func _on_WindGrass_visibility_changed() -> void:
    if visible:
        call_deferred("_setup_multimesh")


func _process(_delta: float) -> void:
    if _character:
        material_override.set_shader_param(
            "character_position", _character.global_transform.origin
        )
