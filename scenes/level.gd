class_name Level
extends Spatial


var is_ready := false
var map: RID


func _ready() -> void:
    Session.level = self
    
    call_deferred("set_up_nav_server")


func set_up_nav_server() -> void:
    map = NavigationServer.map_create()
    NavigationServer.map_set_up(map, Vector3.UP)
    NavigationServer.map_set_active(map, true)
    
    var region := NavigationServer.region_create()
    NavigationServer.region_set_transform(region, Transform())
    NavigationServer.region_set_map(region, map)
    
    var navmesh: NavigationMesh = $NavigationMeshInstance.navmesh
    NavigationServer.region_set_navmesh(region, navmesh)
    
    call_deferred("_on_ready")


func _on_ready() -> void:
    # This lets other classes know that the level state is done being
    # initialized.
    is_ready = true
