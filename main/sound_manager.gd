extends Node

const MASTER_BUS_NAME := "Master"
const MUSIC_BUS_NAME := "Music"
const SFX_BUS_NAME := "SFX"
const BUS_NAME := SFX_BUS_NAME

const SOUND_CONFIG := {
	&"ui_click": {"path": "res://assets/sound/ui_click.wav", "volume_db": -7.0},
	&"menu_next": {"path": "res://assets/sound/ui_click.wav", "volume_db": -7.0},
	&"menu_previous": {"path": "res://assets/sound/ui_click.wav", "volume_db": -8.0, "pitch": 0.92},
	&"menu_equip": {"path": "res://assets/sound/rebinded.mp3", "volume_db": -5.0},
	&"menu_unload": {"path": "res://assets/sound/ui_click.wav", "volume_db": -9.0, "pitch": 0.78},
	&"pause_start": {"path": "res://assets/sound/ui_click.wav", "volume_db": -6.0, "pitch": 0.86},
	&"pause_end": {"path": "res://assets/sound/ui_click.wav", "volume_db": -6.0, "pitch": 1.08},
	&"upgrade_ui_selected": {"path": "res://assets/sound/enhance.wav", "volume_db": -6.0},
	&"rebinded": {"path": "res://assets/sound/rebinded.mp3", "volume_db": -5.0},

	&"attack": {"path": "res://assets/sound/attack.wav", "volume_db": -3.0},
	&"enhance": {"path": "res://assets/sound/enhance.wav", "volume_db": -4.0},
	&"acquire_card": {"path": "res://assets/sound/acquire_card.mp3", "volume_db": -4.0},
	&"checkpoint1": {"path": "res://assets/sound/checkpoint1.mp3", "volume_db": -4.0},
	&"checkpoint2": {"path": "res://assets/sound/checkpoint2.wav", "volume_db": -4.0},
	&"line_broken": {"path": "res://assets/sound/line_broken.mp3", "volume_db": -2.0},
	&"net_break": {"path": "res://assets/sound/net_break.mp3", "volume_db": -2.0},
	&"emitting_bullet": {"path": "res://assets/sound/emmiting_bullet.mp3", "volume_db": -4.0},
	&"emmiting_bullet": {"path": "res://assets/sound/emmiting_bullet.mp3", "volume_db": -4.0},
	&"snake_strike": {"path": "res://assets/sound/SnakeStrike.mp3", "volume_db": -3.0},

	&"body_hurt1": {"path": "res://assets/sound/body_hurt1.mp3", "volume_db": -4.0},
	&"body_hurt2": {"path": "res://assets/sound/body_hurt2.mp3", "volume_db": -4.0},
	&"body_hurt3": {"path": "res://assets/sound/body_hurt3.mp3", "volume_db": -4.0},
	&"enemy_hitted": {"path": "res://assets/sound/enemy_hitted.wav", "volume_db": -5.0},
	&"enemy_death": {"path": "res://assets/sound/enemy_death.wav", "volume_db": -4.0},
	&"game_over": {"path": "res://assets/sound/game_over.mp3", "volume_db": -1.0},

	&"intro": {"path": "res://assets/sound/intro.mp3", "volume_db": -8.0, "bus": MUSIC_BUS_NAME},
	&"battle": {"path": "res://assets/sound/battle.wav", "volume_db": -9.0, "bus": MUSIC_BUS_NAME},
	&"egypt_victory": {"path": "res://assets/sound/Egypt Victory.mp3", "volume_db": -7.0, "bus": MUSIC_BUS_NAME},
}
const AUDIO_BUS_NAMES := {
	&"master": MASTER_BUS_NAME,
	&"music": MUSIC_BUS_NAME,
	&"sfx": SFX_BUS_NAME,
}
const MAX_PLAYERS := 36
const MAX_PER_SOUND := 12
const MIN_VOLUME_DB := -30.0
const SAME_SOUND_STEP_DB := 0.5
const GLOBAL_STEP_DB := 0.5

var _stream_paths: Dictionary = {}        # StringName -> path
var _sound_settings: Dictionary = {}      # StringName -> {volume_db, pitch, delay, bus}
var _streams: Dictionary = {}             # StringName -> AudioStream
var _pending_loads: Array[StringName] = []
var _players: Array[AudioStreamPlayer] = []
var _missing_sound_warnings: Dictionary = {}
var _music_player: AudioStreamPlayer
var _current_music := StringName()

func _ready() -> void:
	setup_audio_buses()
	_init_sound_config()
	set_process(not _pending_loads.is_empty())

func _process(_delta: float) -> void:
	_lazy_load_next()
	if _pending_loads.is_empty():
		set_process(false)

func _init_sound_config() -> void:
	_stream_paths.clear()
	_sound_settings.clear()
	_pending_loads.clear()
	_missing_sound_warnings.clear()
	for name in SOUND_CONFIG.keys():
		var entry: Dictionary = SOUND_CONFIG[name]
		_sound_settings[name] = {
			"volume_db": entry.get("volume_db", 0.0),
			"pitch": entry.get("pitch", 1.0),
			"delay": entry.get("delay", 0.0),
			"bus": entry.get("bus", SFX_BUS_NAME),
		}
		var path = entry.get("path", "")
		if path != "":
			_stream_paths[name] = path
			if ResourceLoader.exists(path):
				_pending_loads.append(name)

func _lazy_load_next() -> void:
	if _pending_loads.is_empty():
		return
	var sound_name = _pending_loads.pop_front()
	_load_stream(sound_name)

func _load_stream(sound_name: StringName) -> AudioStream:
	if _streams.has(sound_name):
		return _streams[sound_name]
	var path = _stream_paths.get(sound_name, "")
	if path == "":
		return null
	if not ResourceLoader.exists(path):
		_warn_missing_sound(sound_name, path)
		return null
	var stream: AudioStream = ResourceLoader.load(path)
	if stream:
		_streams[sound_name] = stream
	else:
		push_warning("Failed to load sound: %s" % path)
	return stream

func play(sound_name: StringName, volume_db = null, pitch = null, delay = null) -> void:
	var stream := _load_stream(sound_name)
	if stream == null:
		if not _stream_paths.has(sound_name):
			push_warning("Sound not registered: %s" % String(sound_name))
		return
	var defaults = _sound_settings.get(sound_name, {"volume_db": 0.0, "pitch": 1.0, "delay": 0.0})
	var final_volume = volume_db if volume_db != null else defaults.get("volume_db", 0.0)
	var final_pitch = pitch if pitch != null else defaults.get("pitch", 1.0)
	var final_delay = delay if delay != null else defaults.get("delay", 0.0)
	var final_bus = defaults.get("bus", SFX_BUS_NAME)
	_play_stream(stream, final_volume, final_pitch, sound_name, final_delay, final_bus)

func _warn_missing_sound(sound_name: StringName, path: String) -> void:
	if _missing_sound_warnings.has(sound_name):
		return
	_missing_sound_warnings[sound_name] = true
	push_warning("Sound resource missing: %s" % path)

func play_SFX(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0, delay: float = 0.0) -> void:
	var name_guess := stream.resource_path.get_file().get_basename() if stream.resource_path != "" else ""
	var sound_name := StringName(name_guess)
	_play_stream(stream, volume_db, pitch, sound_name, delay, SFX_BUS_NAME)

func play_music(sound_name: StringName, volume_db = null, pitch = null, restart := true, loop := true) -> void:
	var stream := _load_stream(sound_name)
	if stream == null:
		if not _stream_paths.has(sound_name):
			push_warning("Music not registered: %s" % String(sound_name))
		return

	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.bus = MUSIC_BUS_NAME
		add_child(_music_player)

	if not restart and _current_music == sound_name and _music_player.playing:
		return

	var defaults = _sound_settings.get(sound_name, {"volume_db": 0.0, "pitch": 1.0})
	var final_volume = volume_db if volume_db != null else defaults.get("volume_db", 0.0)
	var final_pitch = pitch if pitch != null else defaults.get("pitch", 1.0)
	var music_stream: AudioStream = stream.duplicate()
	_apply_stream_loop(music_stream, loop)

	_music_player.stop()
	_music_player.stream = music_stream
	_music_player.volume_db = final_volume
	_music_player.pitch_scale = final_pitch
	_music_player.play()
	_current_music = sound_name


func stop_music() -> void:
	if _music_player != null:
		_music_player.stop()
		_music_player.stream = null
	_current_music = StringName()


func has_sound(sound_name: StringName) -> bool:
	var path = _stream_paths.get(sound_name, "")
	return path != "" and ResourceLoader.exists(path)

func set_sound_defaults(sound_name: StringName, volume_db = null, pitch = null, delay = null) -> void:
	if not _sound_settings.has(sound_name):
		push_warning("Cannot set defaults, sound not registered: %s" % String(sound_name))
		return
	var current = _sound_settings[sound_name]
	if volume_db != null:
		current["volume_db"] = volume_db
	if pitch != null:
		current["pitch"] = pitch
	if delay != null:
		current["delay"] = delay
	_sound_settings[sound_name] = current

func setup_audio_buses() -> void:
	_ensure_audio_bus(MASTER_BUS_NAME)
	_ensure_audio_bus(MUSIC_BUS_NAME, MASTER_BUS_NAME)
	_ensure_audio_bus(SFX_BUS_NAME, MASTER_BUS_NAME)

func get_volume_percent(bus_key: StringName) -> float:
	var bus_name := _resolve_bus_name(bus_key)
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1 or AudioServer.is_bus_mute(bus_index):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)) * 100.0, 0.0, 100.0)

func set_volume_percent(bus_key: StringName, percent: float) -> void:
	var bus_name := _resolve_bus_name(bus_key)
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	var clamped_percent := clampf(percent, 0.0, 100.0)
	if clamped_percent <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, -80.0)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped_percent / 100.0))

func _ensure_audio_bus(bus_name: String, send_bus_name := "") -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	var bus_index := AudioServer.bus_count
	AudioServer.add_bus(bus_index)
	AudioServer.set_bus_name(bus_index, bus_name)
	if send_bus_name != "":
		AudioServer.set_bus_send(bus_index, send_bus_name)

func _resolve_bus_name(bus_key: StringName) -> String:
	if AUDIO_BUS_NAMES.has(bus_key):
		return AUDIO_BUS_NAMES[bus_key]
	return String(bus_key)

func _play_stream(stream: AudioStream, volume_db: float, pitch: float, sound_name: StringName, delay: float = 0.0, bus_name := SFX_BUS_NAME) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	var current_per_sound := _count_playing(sound_name)
	if current_per_sound >= MAX_PER_SOUND:
		return
	var current_total := _count_playing()
	var player := _get_free_player()
	if player == null:
		return
	player.set_meta("sound_name", sound_name)
	player.stream = stream
	player.bus = bus_name
	player.pitch_scale = pitch
	var attenuation = float(current_per_sound) * SAME_SOUND_STEP_DB + max(current_total - 4, 0) * GLOBAL_STEP_DB
	player.volume_db = clamp(volume_db - attenuation, MIN_VOLUME_DB, volume_db)
	player.play()


func _apply_stream_loop(stream: AudioStream, enabled: bool) -> void:
	if stream == null:
		return
	for property_info in stream.get_property_list():
		var property_name := String(property_info.get("name", ""))
		if property_name == "loop":
			stream.set("loop", enabled)
			return
		if property_name == "loop_mode":
			stream.set("loop_mode", 1 if enabled else 0)
			return

func _get_free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	if _players.size() >= MAX_PLAYERS:
		return null
	var player := AudioStreamPlayer.new()
	player.bus = BUS_NAME
	player.finished.connect(_on_player_finished.bind(player))
	add_child(player)
	_players.append(player)
	return player

func _on_player_finished(player: AudioStreamPlayer) -> void:
	var sound_name: StringName = player.get_meta("sound_name", StringName())
	player.stream = null
	player.set_meta("sound_name", StringName())

func _count_playing(target_sound: StringName = StringName()) -> int:
	var count := 0
	for player in _players:
		if not player.playing:
			continue
		if target_sound == StringName() or player.get_meta("sound_name", StringName()) == target_sound:
			count += 1
	return count
