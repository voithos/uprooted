extends Particles

var should_die_after_emitting = false

func _physics_process(delta):
    if should_die_after_emitting and !emitting:
        queue_free()

func emit():
    emitting = true
    $Embers.emitting = true
    $AudioStreamPlayer3D.play()

func emit_and_die():
    emit()
    should_die_after_emitting = true
