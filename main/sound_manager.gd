extends Node

const SOUND_CONFIG := {
	&"attract_player": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/attract player.wav", "volume_db": 0.0, "pitch": 1.0},
	&"bull_dash": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-4/bull_dash.wav", "volume_db": 0.0, "pitch": 1.0},
	&"bull_hit_the_wall": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-4/bull_hit_the_wall.wav", "volume_db": 0.0, "pitch": 1.0},
	&"bull_move": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-4/bull_move.wav", "volume_db": 0.0, "pitch": 1.0},
	&"dash_line_running": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-2/dash_line_running.wav", "volume_db": 0.0, "pitch": 1.0},
	&"drumer_hit": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-2/drumer_hit.wav", "volume_db": 0.0, "pitch": 1.0},
	&"drumer_prehit": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-2/drumer_prehit.wav", "volume_db": 0.0, "pitch": 1.0},
	&"enemy_defeated": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-2/enemy_defeated.wav", "volume_db": 0.0, "pitch": 1.0},
	&"gameover": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/gameover.wav", "volume_db": 0.0, "pitch": 1.0},
	&"grapple_catched": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/grapple_catched.wav", "volume_db": 0.0, "pitch": 1.0},
	&"grapple_outbreak": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/grapple_outbreak.wav", "volume_db": 0.0, "pitch": 1.0},
	&"grapple_pause": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/grapple_pause.wav", "volume_db": 0.0, "pitch": 1.0},
	&"grapple_shooting": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/grapple_shooting.wav", "volume_db": 0.0, "pitch": 1.0},
	&"grapple_wall_contact": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/grapple_wall_contact.wav", "volume_db": 0.0, "pitch": 1.0},
	&"grapple_withdraw": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/grapple_withdraw.wav", "volume_db": 0.0, "pitch": 1.0},
	&"laser_hit_enemy": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/laser_hit_enemy.wav", "volume_db": 0.0, "pitch": 1.0},
	&"level_clear": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-2/level_clear.wav", "volume_db": -10.0, "pitch": 1.0},
	&"maodou_dash": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/maodou_dash.wav", "volume_db": 0.0, "pitch": 1.0},
	&"maodou_dash_shooting": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/maodou_dash_shooting.wav", "volume_db": 0.0, "pitch": 1.0},
	&"maodou_shooting": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/maodou_shooting.wav", "volume_db": 0.0, "pitch": 1.0},
	&"maodou_spit_enemy": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/maodou_spit_enemy.wav", "volume_db": 0.0, "pitch": 1.0},
	&"menu_equip": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/menu_equip.wav", "volume_db": 0.0, "pitch": 1.0},
	&"menu_mouse_button": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/menu_mouse_button.wav", "volume_db": -10.0, "pitch": 1.0},
	&"menu_next": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/menu_next.wav", "volume_db": 0, "pitch": 1.0},
	&"menu_previous": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/menu_previous.wav", "volume_db": 0, "pitch": 1.0},
	&"menu_unload": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/menu_unload.wav", "volume_db": 0.0, "pitch": 1.0},
	&"moudou_descend": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/moudou_descend.wav", "volume_db": 0.0, "pitch": 1.0},
	&"moudou_hp_filled": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/moudou_hp_filled.wav", "volume_db": 0.0, "pitch": 1.0},
	&"moudou_pre_descend": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/moudou_pre_descend.wav", "volume_db": 0.0, "pitch": 1.0},
	&"moudou_touched": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/moudou_touched.wav", "volume_db": 0.0, "pitch": 1.0},
	&"obstacle_applied": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/obstacle_applied.wav", "volume_db": 0.0, "pitch": 1.0},
	&"obstacle_withdrawed": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/obstacle_withdrawed.wav", "volume_db": 0.0, "pitch": 1.0},
	&"pause_end": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/pause_end.wav", "volume_db": 0.0, "pitch": 1.0},
	&"pause_start": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/pause_start.wav", "volume_db": 0.0, "pitch": 1.0},
	&"range_stopped": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/range_stopped.wav", "volume_db": -5.0, "pitch": 1.0},
	&"ranged": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/ranged.wav", "volume_db": -5.0, "pitch": 1.0},
	&"ranger_range_sapar": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/ranger_range_sapar.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_change": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-1/sapar_change.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_enemy_contact001": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/sapar_enemy_contact001.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_enemy_contact002": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/sapar_enemy_contact002.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_enemy_contact003": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/sapar_enemy_contact003.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_gold_contact01": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/sapar_gold_contact01.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_gold_contact02": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/sapar_gold_contact02.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_gold_contact03": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/sapar_gold_contact03.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_gold_contact1": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/sapar_gold_contact1.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_gold_contact2": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/sapar_gold_contact2.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_gold_contact3": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/sapar_gold_contact3.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_shop_packed": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-1/sapar_shop_packed.wav", "volume_db": 0.0, "pitch": 1.0},
	&"sapar_shop_unfold": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-1/sapar_shop_unfold.wav", "volume_db": 0.0, "pitch": 1.0},
	&"shoot_laser": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/shoot_laser.wav", "volume_db": 0.0, "pitch": 1.0},
	&"shooter_preshoot": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-2/shooter_preshoot.wav", "volume_db": 0.0, "pitch": 1.0},
	&"shooter_shoot": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-2/shooter_shoot.wav", "volume_db": 0.0, "pitch": 1.0},
	&"shop_purchase": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/shop_purchase.wav", "volume_db": 0.0, "pitch": 1.0},
	&"shop_recovery": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/shop_recovery.wav", "volume_db": 0.0, "pitch": 1.0},
	&"shop_refresh": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-4/shop_refresh.wav", "volume_db": 0.0, "pitch": 1.0},
	&"spawned": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-2/spawned.wav", "volume_db": 0.0, "pitch": 1.0},
	&"tar_revealed": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/tar_revealed.wav", "volume_db": 0.0, "pitch": 1.0},
	&"trumpet_bullet_shooted": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-2/trumpet_bullet_shooted.wav", "volume_db": 0.0, "pitch": 1.0},
	&"upgrade_ui_focusing": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/upgrade_ui_focusing.wav", "volume_db": 0.0, "pitch": 1.0},
	&"upgrade_ui_selected": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/upgrade_ui_selected.wav", "volume_db": 0.0, "pitch": 1.0},
	&"upgraded": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-3/upgraded.wav", "volume_db": 0.0, "pitch": 1.0},
	&"walker_recover": {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-2/walker_recover.wav", "volume_db": 0.0, "pitch": 1.0},
	&"collect_gold01": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/collect_gold01.wav", "volume_db": 0.0, "pitch": 1.0},
	&"collect_gold02": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/collect_gold02.wav", "volume_db": 0.0, "pitch": 1.0},
	&"collect_gold03": {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/collect_gold03.wav", "volume_db": 0.0, "pitch": 1.0},
	&"hurt_player" : {"path": "res://sound/独立游戏1231/(就佛）独立游戏-01/hurt_player.wav", "volume_db": 0.0, "pitch": 1.0},
	&"bull_hit_enemy" : {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-4/bull_hit_enemy.wav", "volume_db": 0.0, "pitch": 1.0},
	&"attraction" : {"path": "res://sound/独立游戏1231/独立游戏-就佛-02/part-4/attraction.wav", "volume_db": 10, "pitch": 1.0},
}
const MASTER_BUS_NAME := "Master"
const MUSIC_BUS_NAME := "Music"
const SFX_BUS_NAME := "SFX"
const BUS_NAME := SFX_BUS_NAME
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
var _sound_settings: Dictionary = {}      # StringName -> {volume_db, pitch, delay}
var _streams: Dictionary = {}             # StringName -> AudioStream
var _pending_loads: Array[StringName] = []
var _players: Array[AudioStreamPlayer] = []
var _missing_sound_warnings: Dictionary = {}

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
	_play_stream(stream, final_volume, final_pitch, sound_name, final_delay)

func _warn_missing_sound(sound_name: StringName, path: String) -> void:
	if _missing_sound_warnings.has(sound_name):
		return
	_missing_sound_warnings[sound_name] = true
	push_warning("Sound resource missing: %s" % path)

func play_SFX(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0, delay: float = 0.0) -> void:
	var name_guess := stream.resource_path.get_file().get_basename() if stream.resource_path != "" else ""
	var sound_name := StringName(name_guess)
	_play_stream(stream, volume_db, pitch, sound_name, delay)

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

func _play_stream(stream: AudioStream, volume_db: float, pitch: float, sound_name: StringName, delay: float = 0.0) -> void:
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
	player.pitch_scale = pitch
	var attenuation = float(current_per_sound) * SAME_SOUND_STEP_DB + max(current_total - 4, 0) * GLOBAL_STEP_DB
	player.volume_db = clamp(volume_db - attenuation, MIN_VOLUME_DB, volume_db)
	player.play()

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
