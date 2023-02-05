class_name ScreenPanel
extends PanelContainer


const LEVEL_SCENE := preload("res://scenes/level/MainLevel.tscn")

const PRESS_ANY_KEY_DELAY := 0.0 if Global.IS_DEBUG else 1.0
const PRESS_ANY_KEY_FADE_DURATION := 1.2

const SCREEN_FADE_IN_DURATION := 0.3
const SCREEN_FADE_OUT_DURATION := 0.4

var is_open := false
var press_any_key_tween: Tween
var screen_fade_tween: Tween


func _ready() -> void:
    press_any_key_tween = Tween.new()
    press_any_key_tween.connect(
        "tween_completed", self, "_on_press_any_key_tween_completed")
    add_child(press_any_key_tween)
    
    screen_fade_tween = Tween.new()
    screen_fade_tween.connect(
        "tween_completed", self, "_on_screen_fade_tween_completed")
    add_child(screen_fade_tween)
    
    get_viewport().connect(
        "size_changed",
        self,
        "_on_resized")
    _on_resized()


func _input(event):
    if (event is InputEventKey or \
            event is InputEventMouseButton) and \
            event.is_pressed():
        _start_new_level()


func set_is_open(value: bool, fades := true) -> void:
    is_open = value
    
    press_any_key_tween.stop_all()
    screen_fade_tween.stop_all()
    
    if is_open:
        get_node("%PressAnyKey").modulate.a = 0.0
        press_any_key_tween.interpolate_property(
            get_node("%PressAnyKey"),
            "modulate:a",
            0.0,
            1.0,
            PRESS_ANY_KEY_FADE_DURATION,
            Tween.TRANS_QUAD,
            Tween.EASE_IN,
            PRESS_ANY_KEY_DELAY)
        press_any_key_tween.start()
    
    var start_opacity: float
    var end_opacity: float
    var duration: float
    var ease_type: int
    if is_open:
        start_opacity = 0.0
        end_opacity = 1.0
        duration = SCREEN_FADE_IN_DURATION
        ease_type = Tween.EASE_IN
    else:
        start_opacity = 1.0
        end_opacity = 0.0
        duration = SCREEN_FADE_OUT_DURATION
        ease_type = Tween.EASE_OUT
    
    if fades:
        self.modulate.a = start_opacity
        screen_fade_tween.interpolate_property(
            self,
            "modulate:a",
            start_opacity,
            end_opacity,
            duration,
            Tween.TRANS_QUAD,
            ease_type)
        screen_fade_tween.start()
    else:
        self.modulate.a = end_opacity


func _on_press_any_key_tween_completed(object: Object, key: NodePath) -> void:
    pass


func _on_screen_fade_tween_completed(object: Object, key: NodePath) -> void:
    pass


func _on_resized() -> void:
    self.rect_size = get_viewport().size


func _start_new_level() -> void:
    Session.reset()
    Screen.get_hud().set_is_shown(true)
    var level := LEVEL_SCENE.instance()
    var main_node := self.owner
    main_node.add_child(level)
    main_node.move_child(level, 1)
    set_is_open(false)
