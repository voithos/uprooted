extends Spatial

const BULLET_SPEED = 50
var LIFETIME = 2.0

var age = 0.0

func _physics_process(delta: float) -> void:
    var forward_dir = global_transform.basis.z.normalized()
    global_translate(forward_dir * BULLET_SPEED * delta)
    
    age += delta
    if age > LIFETIME:
        queue_free()
