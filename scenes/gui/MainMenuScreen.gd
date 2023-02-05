class_name MainMenuScreen
extends ScreenPanel


func _ready() -> void:
    includes_delay_for_starting_new_level = false
    set_is_open(true, false)
    Music.play(Music.MAINMENU)


func _on_resized() -> void:
    ._on_resized()
    $MarginContainer.rect_size = rect_size
