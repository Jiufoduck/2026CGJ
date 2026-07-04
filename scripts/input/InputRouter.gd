extends Node

signal gamepad_assignments_changed

# 脚本说明：
# - INPUT_PRESET_KEYBOARD/INPUT_PRESET_GAMEPAD：当前输入模式名称，HUD 切换预设时会同步到这里。
# - JOY_AXIS_DEADZONE：摇杆方向判定死区，避免轻微漂移触发移动。
# - active_input_preset：当前输入预设。手柄预设下会按玩家分配的设备读取输入。
# - player_devices：玩家到手柄 device id 的映射。P1 使用第一个手柄，P2 使用第二个手柄。
# - connected_joypads_snapshot：上一帧看到的手柄列表，用于补充 joy_connection_changed 在部分平台不稳定的情况。
# - pressed_cache/just_pressed_cache：每个玩家动作的当前按下和刚按下状态，用于卡牌输入等一次性动作。
# - _ready()：设为全局常驻处理，补齐手柄 UI 确认/取消/导航动作，监听手柄连接变化，并初次分配手柄。
# - _physics_process(delta)：每帧刷新每个玩家动作的刚按下状态。
# - set_active_input_preset(preset_name)：HUD 切换键盘/手柄预设时调用。
# - refresh_gamepad_assignments()：读取当前连接的手柄并重新分配给两名玩家。
# - get_player_device(player_id)：返回某名玩家当前分配到的手柄 device id；-1 表示未分配。
# - get_player_move_vector(player_id)：读取指定玩家的移动向量。手柄模式下只读取该玩家自己的手柄。
# - is_player_action_just_pressed(player_id, action_name)：读取指定玩家某动作是否刚按下。手柄模式下按设备过滤。
# - _assign_connected_joypads(connected_joypads)：按顺序把连接的手柄分给 P1/P2。
# - _refresh_gamepad_assignments_if_needed()：每帧检查手柄列表变化，保证游戏开始后插入手柄也能分配。
# - _ensure_default_ui_actions()：保证手柄 A/B/Menu、十字键和左摇杆能操作聚焦 UI 控件。
# - _get_action_strength_for_player(action_name, player_id)：按 InputMap 中当前预设的事件计算某动作强度。
# - _is_action_pressed_for_player(action_name, player_id)：按当前玩家手柄 device 判断按钮/轴动作是否按下。
# - _get_event_strength_for_device(input_event, device_id)：把某个 InputMap 事件换算成指定手柄上的强度。

const INPUT_PRESET_KEYBOARD := "keyboard"
const INPUT_PRESET_GAMEPAD := "gamepad"
const JOY_AXIS_DEADZONE := 0.25
const TRACKED_PLAYER_ACTIONS := [
	"p1_play_card",
	"p1_pass_card",
	"p2_play_card",
	"p2_pass_card",
]

var active_input_preset := INPUT_PRESET_GAMEPAD
var player_devices := {
	1: -1,
	2: -1,
}
var connected_joypads_snapshot := []
var pressed_cache := {}
var just_pressed_cache := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100
	_ensure_default_ui_actions()
	refresh_gamepad_assignments()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _physics_process(_delta: float) -> void:
	_refresh_gamepad_assignments_if_needed()
	_refresh_just_pressed_cache()


func set_active_input_preset(preset_name: String) -> void:
	if preset_name == INPUT_PRESET_KEYBOARD:
		active_input_preset = INPUT_PRESET_KEYBOARD
	else:
		active_input_preset = INPUT_PRESET_GAMEPAD
		refresh_gamepad_assignments()
	_refresh_just_pressed_cache()


func get_active_input_preset() -> String:
	return active_input_preset


func refresh_gamepad_assignments() -> void:
	var connected_joypads := Input.get_connected_joypads()
	connected_joypads_snapshot = _normalize_joypad_list(connected_joypads)
	_assign_connected_joypads(connected_joypads)


func get_player_device(player_id: int) -> int:
	return int(player_devices.get(player_id, -1))


func get_player_device_name(player_id: int) -> String:
	var device_id := get_player_device(player_id)
	if device_id < 0:
		return "未分配"
	return Input.get_joy_name(device_id)


func get_player_move_vector(player_id: int) -> Vector2:
	if active_input_preset == INPUT_PRESET_KEYBOARD:
		return Input.get_vector(
			"p%d_move_left" % player_id,
			"p%d_move_right" % player_id,
			"p%d_move_up" % player_id,
			"p%d_move_down" % player_id
		)

	var left := _get_action_strength_for_player("p%d_move_left" % player_id, player_id)
	var right := _get_action_strength_for_player("p%d_move_right" % player_id, player_id)
	var up := _get_action_strength_for_player("p%d_move_up" % player_id, player_id)
	var down := _get_action_strength_for_player("p%d_move_down" % player_id, player_id)
	return Vector2(right - left, down - up).limit_length(1.0)


func is_player_action_just_pressed(player_id: int, action_name: StringName) -> bool:
	if active_input_preset == INPUT_PRESET_KEYBOARD:
		return Input.is_action_just_pressed(action_name)
	return bool(just_pressed_cache.get(_make_cache_key(player_id, action_name), false))


func is_player_action_pressed(player_id: int, action_name: StringName) -> bool:
	if active_input_preset == INPUT_PRESET_KEYBOARD:
		return Input.is_action_pressed(action_name)
	return bool(pressed_cache.get(_make_cache_key(player_id, action_name), false))


func _on_joy_connection_changed(_device_id: int, _connected: bool) -> void:
	refresh_gamepad_assignments()


func _assign_connected_joypads(connected_joypads: Array) -> void:
	var previous_player_one_device := get_player_device(1)
	var previous_player_two_device := get_player_device(2)
	var sorted_devices := connected_joypads.duplicate()
	sorted_devices.sort()
	player_devices[1] = int(sorted_devices[0]) if sorted_devices.size() >= 1 else -1
	player_devices[2] = int(sorted_devices[1]) if sorted_devices.size() >= 2 else -1
	pressed_cache.clear()
	just_pressed_cache.clear()
	if previous_player_one_device != get_player_device(1) or previous_player_two_device != get_player_device(2):
		gamepad_assignments_changed.emit()


func _refresh_gamepad_assignments_if_needed() -> void:
	var current_snapshot := _normalize_joypad_list(Input.get_connected_joypads())
	if current_snapshot == connected_joypads_snapshot:
		return

	connected_joypads_snapshot = current_snapshot
	_assign_connected_joypads(current_snapshot)


func _normalize_joypad_list(joypads: Array) -> Array:
	var normalized := []
	for device_id in joypads:
		normalized.append(int(device_id))
	normalized.sort()
	return normalized


func _ensure_default_ui_actions() -> void:
	_ensure_ui_joy_button(&"ui_accept", JOY_BUTTON_A)
	_ensure_ui_joy_button(&"ui_cancel", JOY_BUTTON_B)
	_ensure_ui_joy_button(&"ui_menu", JOY_BUTTON_START)
	_ensure_ui_joy_button(&"ui_left", JOY_BUTTON_DPAD_LEFT)
	_ensure_ui_joy_button(&"ui_right", JOY_BUTTON_DPAD_RIGHT)
	_ensure_ui_joy_button(&"ui_up", JOY_BUTTON_DPAD_UP)
	_ensure_ui_joy_button(&"ui_down", JOY_BUTTON_DPAD_DOWN)
	_ensure_ui_joy_axis(&"ui_left", JOY_AXIS_LEFT_X, -1.0)
	_ensure_ui_joy_axis(&"ui_right", JOY_AXIS_LEFT_X, 1.0)
	_ensure_ui_joy_axis(&"ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_ensure_ui_joy_axis(&"ui_down", JOY_AXIS_LEFT_Y, 1.0)


func _ensure_ui_joy_button(action_name: StringName, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)

	for input_event in InputMap.action_get_events(action_name).duplicate():
		if input_event is InputEventJoypadButton and (input_event as InputEventJoypadButton).button_index == button_index:
			if input_event.device != -1:
				InputMap.action_erase_event(action_name, input_event)
				break
			return

	var button_event := InputEventJoypadButton.new()
	button_event.device = -1
	button_event.button_index = button_index
	InputMap.action_add_event(action_name, button_event)


func _ensure_ui_joy_axis(action_name: StringName, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)

	for input_event in InputMap.action_get_events(action_name).duplicate():
		if input_event is InputEventJoypadMotion:
			var motion_event := input_event as InputEventJoypadMotion
			if motion_event.axis == axis and is_equal_approx(motion_event.axis_value, axis_value):
				if motion_event.device != -1:
					InputMap.action_erase_event(action_name, input_event)
					break
				return

	var axis_event := InputEventJoypadMotion.new()
	axis_event.device = -1
	axis_event.axis = axis
	axis_event.axis_value = axis_value
	InputMap.action_add_event(action_name, axis_event)


func _refresh_just_pressed_cache() -> void:
	for action_name in TRACKED_PLAYER_ACTIONS:
		var player_id := 1
		if String(action_name).begins_with("p2_"):
			player_id = 2

		var cache_key := _make_cache_key(player_id, StringName(action_name))
		var was_pressed := bool(pressed_cache.get(cache_key, false))
		var is_pressed := _is_action_pressed_for_player(StringName(action_name), player_id)
		pressed_cache[cache_key] = is_pressed
		just_pressed_cache[cache_key] = is_pressed and not was_pressed


func _make_cache_key(player_id: int, action_name: StringName) -> String:
	return "%d:%s" % [player_id, String(action_name)]


func _get_action_strength_for_player(action_name: String, player_id: int) -> float:
	var device_id := get_player_device(player_id)
	if device_id < 0 or not InputMap.has_action(action_name):
		return 0.0

	var strongest := 0.0
	for input_event in InputMap.action_get_events(action_name):
		strongest = maxf(strongest, _get_event_strength_for_device(input_event, device_id))
	return strongest


func _is_action_pressed_for_player(action_name: StringName, player_id: int) -> bool:
	var device_id := get_player_device(player_id)
	if device_id < 0 or not InputMap.has_action(action_name):
		return false

	for input_event in InputMap.action_get_events(action_name):
		if _get_event_strength_for_device(input_event, device_id) >= 1.0:
			return true
	return false


func _get_event_strength_for_device(input_event: InputEvent, device_id: int) -> float:
	if input_event is InputEventJoypadButton:
		var button_event := input_event as InputEventJoypadButton
		return 1.0 if Input.is_joy_button_pressed(device_id, button_event.button_index) else 0.0

	if input_event is InputEventJoypadMotion:
		var motion_event := input_event as InputEventJoypadMotion
		var current_axis_value := Input.get_joy_axis(device_id, motion_event.axis)
		if signf(current_axis_value) != signf(motion_event.axis_value):
			return 0.0
		var absolute_value := absf(current_axis_value)
		if absolute_value <= JOY_AXIS_DEADZONE:
			return 0.0
		return clampf(inverse_lerp(JOY_AXIS_DEADZONE, 1.0, absolute_value), 0.0, 1.0)

	return 0.0
