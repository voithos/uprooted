extends Node

func shake(duration, frequency, amplitude):
    var player = get_tree().get_nodes_in_group("player")[0]
    player.camera.shake(duration, frequency, amplitude)
