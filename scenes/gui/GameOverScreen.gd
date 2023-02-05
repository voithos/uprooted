tool
class_name GameOverScreen
extends ScreenPanel


const MARGIN_RATIO := 0.2


func set_is_open(value: bool, fades := true) -> void:
    .set_is_open(value, fades)
    get_node("%Score").text = str(Session.score)
    get_node("%WaveCount").text = str(Session.waves_completed)


func _on_resized() -> void:
    ._on_resized()
    $MarginContainer.rect_size = rect_size
    $MarginContainer/CenterContainer/PanelContainer.rect_min_size = \
        rect_size * (1.0 - MARGIN_RATIO * 2)


func _on_zaven_pressed():
    OS.shell_open("https://voithos.io")


func _on_levi_pressed():
    OS.shell_open("https://levi.dev")
