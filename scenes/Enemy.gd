class_name Enemy
extends KinematicBody


enum {
    UNKNOWN,
    SMALL,
    MEDIUM, # Gunner
    LARGE,
}

const SCORES := {
    SMALL: 100,
    MEDIUM: 300,
    LARGE: 900,
}

const HALF_HEIGHT := {
    SMALL: (0.89 + 0.002) * 0.868,
    MEDIUM: 0.89,
    LARGE: 0.89,
}

const HALF_WIDTH := {
    SMALL: (0.89 + 0.002) * 0.868,
    MEDIUM: 0.89,
    LARGE: 0.89,
}

const NAVIGATION_INTERVAL := 1.0
const OPTIMIZE_PATH := true
export var TRAVEL_SPEED_RATIO_OF_PLAYER_SPEED := 0.75
const TRAVEL_SPEED_RANDOM_SLOWDOWN_RATIO := 0.18
const TRAVEL_DIRECTION_RANDOM_DEVIATION_MAX := PI / 15
const MAX_SLOPE_ANGLE := deg2rad(50.0)
const STOP_ON_SLOPES := true
const DAMAGE_TAKEN := 1.0

var travel_speed: float
var timer: Timer
var path: PoolVector3Array
var path_index := 0
var is_facing_direction_of_travel := true
var velocity := Vector3.ZERO

export (float) var max_health = 3.0
onready var health = max_health

export var type := SMALL


func _ready():
    travel_speed = \
        TRAVEL_SPEED_RATIO_OF_PLAYER_SPEED * Player.MAX_SPEED * \
        (1.0 - randf() * TRAVEL_SPEED_RANDOM_SLOWDOWN_RATIO)
    
    set_up_timer()
    set_health(max_health)

func set_health(value):
    health = clamp(value, 0, max_health)
    var progress: float = health / max_health
    $BillboardHealthBar.set_progress(progress)
    $BillboardHealthBar.visible = progress < 1.0
    if health == 0:
        die()

func take_damage():
    set_health(health - DAMAGE_TAKEN)

func die():
    Session.add_score(SCORES[type])
    queue_free()

func set_up_timer() -> void:
    timer = Timer.new()
    timer.autostart = true
    timer.wait_time = NAVIGATION_INTERVAL
    timer.connect("timeout", self, "navigate")
    add_child(timer)


func _physics_process(delta: float):
    if !Session.is_player_and_level_ready:
        return
    
    # Handle moving platforms.
    var snap := -get_floor_normal() - get_floor_velocity() * delta
    
    if !is_on_floor():
        # While airborne, don't alter horizontal velocity.
        snap = Vector3.ZERO
        velocity.y -= Session.player.GRAVITY * delta
    elif path.empty() or \
            path_index >= path.size():
        # We aren't navigating.
        velocity = Vector3.ZERO
    else:
        travel_along_path(delta)
    
    move_and_slide_with_snap(
        velocity, snap, Vector3.UP, STOP_ON_SLOPES, 4, MAX_SLOPE_ANGLE)


func travel_along_path(delta: float) -> void:
    var travel_distance := delta * travel_speed
    var target := path[path_index]
    var displacement_to_target := target - global_translation
    displacement_to_target.y = 0
    var is_displacement_negligible := \
        displacement_to_target.length_squared() < 0.001
    var travel_direction := \
        Vector3.BACK if \
        is_displacement_negligible else \
        displacement_to_target.normalized()
    
    if travel_distance * travel_distance > \
            displacement_to_target.length_squared():
        # Move directly to the target, and don't overshoot it.
        path_index += 1
        
        # TODO: Include movement along the next path segment for the remainder
        #       of travel distance.
    else:
        # Add random deviation to the travel direction to help enemies clump
        # less and look more realistic.
        var rotation := randf() * TRAVEL_DIRECTION_RANDOM_DEVIATION_MAX
        if randf() < 0.5:
            rotation *= -1
        travel_direction.rotated(Vector3.UP, rotation)
            
        displacement_to_target = travel_direction * travel_distance
    
    var travel_velocity := displacement_to_target / delta
    velocity.x = travel_velocity.x
    velocity.y = 0.0
    velocity.z = travel_velocity.z
    
    # Face the direction we move.
    if !is_displacement_negligible and is_facing_direction_of_travel:
        var look_at_point := global_translation + travel_direction
        look_at(look_at_point, Vector3.UP)


func navigate() -> void:
    if !Session.is_player_and_level_ready:
        # Demo level ?
        return

    path = NavigationServer.map_get_path(
        Session.level.map,
        global_translation,
        Session.player.global_translation,
        OPTIMIZE_PATH)
    path_index = 0


func _on_Hurtbox_body_entered(body):
    take_damage()
