tool
class_name GameOverScreen
extends ScreenPanel


const MARGIN_RATIO := 0.2

const GAME_OVER_MESSAGES := [
    "You got chopped!",
    "Splintered!",
    "Turned into toothpicks!",
]


func _ready() -> void:
    includes_delay_for_starting_new_level = true


func set_is_open(value: bool, fades := true) -> void:
    .set_is_open(value, fades)
    get_node("%Header").text = _get_game_over_message()
    get_node("%Score").text = str(Session.score)
    get_node("%WaveCount").text = str(Session.waves_completed + 1)
    if is_open:
        Screen.get_hud().set_is_shown(false)


func _on_resized() -> void:
    ._on_resized()
    $MarginContainer.rect_size = rect_size
    $MarginContainer/CenterContainer/PanelContainer.rect_min_size = \
        rect_size * (1.0 - MARGIN_RATIO * 2)


func _get_game_over_message() -> String:
    var index := min(
        floor(randf() * GAME_OVER_MESSAGES.size()),
        GAME_OVER_MESSAGES.size() - 1)
    return GAME_OVER_MESSAGES[index]


func _on_zaven_pressed():
    OS.shell_open("https://voithos.io")


func _on_levi_pressed():
    OS.shell_open("https://levi.dev")
