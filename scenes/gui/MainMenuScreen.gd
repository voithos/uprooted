class_name MainMenuScreen
extends ScreenPanel


func _ready() -> void:
    set_is_open(true, false)


func _on_resized() -> void:
    ._on_resized()
    $MarginContainer.rect_size = rect_size
