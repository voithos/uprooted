extends Node

# Centralized SFX management.

const SFX_DB = -8.0
const QUIET_DB = -12.0
const EXTRA_QUIET_DB = -20.0
const EVEN_QUIETER_DB = -25.0
const BACKGROUND_QUIET_DB = -40.0

# Preloaded sound effects.
# ========================
enum {
    EXAMPLE,
}

const SAMPLES = {
    EXAMPLE: preload("res://assets/sfx/example.wav"),
}
# ========================

# Max number of simultaneously-playing sfx.
const POOL_SIZE = 8
var pool = []
# Index of the current audio player in the pool.
var next_player = 0

func _ready():
    _init_stream_players()

func _init_stream_players():
    # warning-ignore:unused_variable
    for i in range(POOL_SIZE):
        var player = AudioStreamPlayer.new()
        add_child(player)
        pool.append(player)

func _get_next_player_idx():
    var next = next_player
    next_player = (next_player + 1) % POOL_SIZE
    return next

func play(sample, db=SFX_DB):
    var idx = _get_next_player_idx()
    var player = pool[idx]
    play_with_player(player, sample, db)

# Use this with an audio player that exists in the scene.
func play_with_player(player, sample, db=SFX_DB):
    assert(sample in SAMPLES)
    var stream = SAMPLES[sample]
    player.stream = stream
    player.volume_db = db
    player.play()
