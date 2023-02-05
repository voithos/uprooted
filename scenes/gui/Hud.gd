tool
class_name Hud
extends Control


const MARGIN := 10.0

const FADE_IN_DURATION := 1.0
const FADE_OUT_DURATION := 0.7

const FADE_IN_DELAY := 0.1
const FADE_OUT_DELAY := 0.0

const HEALTH_DURATION := 0.6

var is_shown := false
var fade_tween: Tween
var health_tween: Tween


func _ready() -> void:
    fade_tween = Tween.new()
    fade_tween.connect("tween_completed", self, "_fade_tween_completed")
    add_child(fade_tween)
    
    health_tween = Tween.new()
    health_tween.connect("tween_completed", self, "_health_tween_completed")
    add_child(health_tween)
    
    get_viewport().connect(
        "size_changed",
        self,
        "_on_resized")
    _on_resized()


func reset() -> void:
    set_is_shown(false, false)
    update_health(false)
    update_score()
    update_waves()


func _process(delta: float) -> void:
    if !is_instance_valid(Session.player):
        return
    
    var wave_cooldown_progress := get_node("%WaveCooldownProgress")
    var wave_cooldown_background := get_node("%WaveCooldownBackground")
    wave_cooldown_progress.rect_min_size.x = \
        Session.level.enemy_manager.get_wave_cooldown_progress() * \
        wave_cooldown_background.rect_size.x
    
    if Session.player.get_is_rooted_near_pool():
        var color := Session.player.pool.get_progress_bar_color()
        var hydration_progress := get_node("%HydrationProgress")
        var hydration_background := get_node("%HydrationBackground")
        hydration_progress.color = color
        hydration_progress.rect_min_size.x = \
            Session.player.pool.get_hydration_progress() * \
            hydration_background.rect_size.x


func update_score() -> void:
    get_node("%Score").text = \
        str(Session.score) if \
        is_shown else \
        "0"


func update_waves() -> void:
    get_node("%Waves").text = \
        str(Session.waves_completed + 1) if \
        is_shown else \
        "0"


func update_health(fades := true, delays := false) -> void:
    var health_remaining: ColorRect = get_node("%HealthRemaining")
    var health_lost: ColorRect = get_node("%HealthLost")
    
    var health_ratio: float
    if Session.is_player_and_level_ready and \
            Session.player.is_alive and \
            is_shown:
        health_ratio = Session.player.health / Session.player.MAX_HEALTH
    else:
        health_ratio = 0.0
    var health_bar_width := health_lost.rect_size.x
    var health_remaining_width := health_bar_width * health_ratio
    
    health_tween.stop_all()
    
    if fades:
        var delay := \
            (FADE_IN_DURATION + FADE_IN_DELAY) * 0.9 if \
            delays else \
            0.0
        health_tween.interpolate_property(
            health_remaining,
            "rect_min_size:x",
            health_remaining.rect_min_size.x,
            health_remaining_width,
            HEALTH_DURATION,
            Tween.TRANS_QUAD,
            Tween.EASE_OUT,
            delay)
        health_tween.start()
    else:
        health_remaining.rect_min_size.x = health_remaining_width


func _on_resized() -> void:
    self.rect_size = get_viewport().size
    $MarginContainer.rect_size = self.rect_size
    $MarginContainer.add_constant_override("margin_top", MARGIN)
    $MarginContainer.add_constant_override("margin_bottom", MARGIN)
    $MarginContainer.add_constant_override("margin_left", MARGIN)
    $MarginContainer.add_constant_override("margin_right", MARGIN)


func set_is_shown(value: bool, fades := true) -> void:
    is_shown = value
    
    var start: float
    var end: float
    var duration: float
    var delay: float
    var ease_type: int
    if is_shown:
        start = 0.0
        end = 1.0
        duration = FADE_IN_DURATION
        delay = FADE_IN_DELAY
        ease_type = Tween.EASE_IN
    else:
        start = 1.0
        end = 0.0
        duration = FADE_OUT_DURATION
        delay = FADE_OUT_DELAY
        ease_type = Tween.EASE_OUT
    
    fade_tween.stop_all()
    
    if fades:
        self.modulate.a = start
        fade_tween.interpolate_property(
            self,
            "modulate:a",
            start,
            end,
            duration,
            Tween.TRANS_QUAD,
            ease_type,
            delay)
        fade_tween.start()
    else:
        self.modulate.a = end


func set_is_pool_hydration_shown(value: bool) -> void:
    get_node("%HydrationBar").visible = value
    get_node("%HydrationBarSpacer").visible = value
    if value:
        var color := Session.player.pool.get_progress_bar_color()
        get_node("%HydrationProgress").color = color


func _fade_tween_completed(object: Object, key: NodePath) -> void:
    pass


func _health_tween_completed(object: Object, key: NodePath) -> void:
    pass
