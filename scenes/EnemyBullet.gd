extends KinematicBody

const BULLET_SPEED = 10
var LIFETIME = 5.0

var age = 0.0
var is_exploding = false


func _physics_process(delta: float) -> void:
    if is_exploding:
        # Wait until particles are done emitting
        if not $Particles.emitting:
            queue_free()
        return

    var forward_dir = -global_transform.basis.z.normalized()
    
    var collision = move_and_collide(forward_dir * BULLET_SPEED * delta)
    if collision:
        global_translation = collision.position
        explode()
    
    age += delta
    if age > LIFETIME:
        explode()
    
func explode():
    if is_exploding:
        return
    
    is_exploding = true
    $fireball_vfx.hide()
    $Particles.emitting = true
