class_name Enemy
extends KinematicBody


const NAVIGATION_INTERVAL := 1.0
const OPTIMIZE_PATH := true
const TRAVEL_SPEED := 10.0
const MAX_SLOPE_ANGLE := deg2rad(45.0)
const STOP_ON_SLOPES := true

var timer: Timer
var path: PoolVector3Array
var path_index := 0
var is_facing_direction_of_travel := true
var velocity := Vector3.ZERO


func _ready():
    set_up_timer()


func set_up_timer() -> void:
    timer = Timer.new()
    timer.autostart = true
    timer.wait_time = NAVIGATION_INTERVAL
    timer.connect("timeout", self, "navigate")
    add_child(timer)


func _physics_process(delta: float):
    if !Session.is_level_ready:
        return
    
    # Handle moving platforms.
    var snap := -get_floor_normal() - get_floor_velocity() * delta
    
    if !is_on_floor():
        # While airborne, don't alter horizontal velocity.
        snap = Vector3.ZERO
    elif path.empty() or \
            path_index >= path.size():
        # We aren't navigating.
        velocity = Vector3.ZERO
    else:
        travel_along_path(delta)
    
    velocity.y -= Session.player.GRAVITY * delta
    
    move_and_slide_with_snap(
        velocity, snap, Vector3.UP, STOP_ON_SLOPES, 4, MAX_SLOPE_ANGLE)


func travel_along_path(delta: float) -> void:
    var travel_distance := delta * TRAVEL_SPEED
    var target := path[path_index]
    var displacement_to_target := target - global_translation
    var is_displacement_negligible := \
        displacement_to_target.length_squared() < 0.001
    var travel_direction := \
        Vector3.UP if \
        is_displacement_negligible else \
        displacement_to_target.normalized()
    
    var travel_displacement: Vector3
    if travel_distance * travel_distance > \
            displacement_to_target.length_squared():
        # Move directly to the target, and don't overshoot it.
        travel_displacement = displacement_to_target
        path_index += 1
        
        # TODO: Include movement along the next path segment for the remainder
        #       of travel distance.
    else:
        displacement_to_target = travel_direction * travel_distance
    
    var travel_velocity := displacement_to_target / delta
    velocity.x = travel_velocity.x
    velocity.z = travel_velocity.z
    
    # Face the direction we move.
    if !is_displacement_negligible and is_facing_direction_of_travel:
        var look_at_point := global_translation + travel_direction
        look_at(look_at_point, Vector3.UP)


func navigate() -> void:
    path = NavigationServer.map_get_path(
        Session.level.map,
        global_translation,
        Session.player.global_translation,
        OPTIMIZE_PATH)
    path_index = 0
