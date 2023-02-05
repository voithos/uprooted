class_name Level
extends Spatial


var is_ready := false
var map: RID
var terrain: Terrain
var pool_manager: PoolManager
var enemy_manager: EnemyManager


func _ready() -> void:
    Session.level = self
    
    terrain = $SmallEnemyNavMesh/Terrain
    
    pool_manager = PoolManager.new()
    add_child(pool_manager)
    enemy_manager = EnemyManager.new()
    add_child(enemy_manager)
    
    call_deferred("set_up_nav_server")


func set_up_nav_server() -> void:
    map = NavigationServer.map_create()
    NavigationServer.map_set_up(map, Vector3.UP)
    NavigationServer.map_set_active(map, true)
    
    var region := NavigationServer.region_create()
    NavigationServer.region_set_transform(region, Transform())
    NavigationServer.region_set_map(region, map)
    
    var navmesh: NavigationMesh = $SmallEnemyNavMesh.navmesh
    NavigationServer.region_set_navmesh(region, navmesh)
    
    call_deferred("_on_ready")


func _on_ready() -> void:
    # This lets other classes know that the level state is done being
    # initialized.
    is_ready = true
    pool_manager.on_player_ready()
    Screen.get_hud().update_health(true, true)
