extends Spatial

var bullet_scene = preload("res://scenes/Bullet.tscn")

func _ready():
    pass # Replace with function body.
    
func spawn_bullet():
    var b = bullet_scene.instance()
    var scene_root = get_tree().root.get_children()[0]
    scene_root.add_child(b)
    
    b.global_transform = global_transform
