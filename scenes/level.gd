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
    
    Music.play(Music.GAMEPLAY)


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


func get_heightmap_height_at_position(position: Vector3) -> float:
    var from := position
    from.y = 1000.0
    
#    var to := global_translation
#    to.y = 0.0
#    var exclude := []
#    var collision_mask := Global.WORLD_COLLISION_MASK
#    var collide_with_bodies := true
#    var collide_with_areas := false
#    var space_state := get_world().direct_space_state
#    var result := space_state.intersect_ray(
#        from,
#        to,
#        exclude,
#        collision_mask,
#        collide_with_bodies)
#    global_translation = result.position
    
#    var direction := Vector3.DOWN
#    var max_distance := 1000.0
#    global_translation = \
#        Session.level.terrain.cell_raycast(from, direction, max_distance)
    
    var heightmap_cell_position: Vector3 = terrain.world_to_map(from)
    
#    var heightmap_image: Image = terrain._data.get_image(HTerrainData.CHANNEL_HEIGHT)
#    var height: float = terrain._get_height_or_default(image, heightmap_cell_position.x, heightmap_cell_position.z)

    return terrain._data.get_height_at(
        heightmap_cell_position.x, heightmap_cell_position.z)
