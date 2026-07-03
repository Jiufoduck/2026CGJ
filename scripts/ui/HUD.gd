extends CanvasLayer
class_name GameHUD

# 脚本说明：
# - health_label：显示肉体血量文字的 Label。文档要求血量放在醒目位置，因此它位于 HUD 顶部。
# - health_bar：显示肉体血量比例的 ProgressBar。它和 health_label 一起强化受击反馈。
# - link_status_label：显示连线稳定、断线倒计时、胜利或失败状态的 Label。
# - death_countdown_panel：断线后显示在屏幕上的死亡倒计时面板，避免只在底部状态栏里显示而被忽略。
# - death_countdown_label：死亡倒计时数字文本。BodyCore 断线倒计时每帧刷新它。
# - player_one_card_label：玩家 1 当前牌显示。它只读牌堆顶，不改变牌堆。
# - player_two_card_label：玩家 2 当前牌显示。它只读牌堆顶，不改变牌堆。
# - player_one_count_label：玩家 1 当前战斗牌堆剩余数量。
# - player_two_count_label：玩家 2 当前战斗牌堆剩余数量。
# - message_label：显示最近一次卡牌、任务点或结束状态消息。
# - reward_choice_overlay：任务点奖励三选一界面根节点。默认隐藏，玩家到达专属任务点后显示。
# - reward_choice_panel：任务点奖励三选一界面的中心面板。显示/隐藏动画会缩放它。
# - reward_title_label：奖励界面标题，显示是哪个玩家正在选择奖励。
# - reward_hint_label：奖励界面提示，说明只能选择一张牌加入该玩家牌堆。
# - reward_choice_buttons：三个奖励按钮的数组。每个按钮对应一张候选牌，按钮文本由卡牌名称、类型和说明组成。
# - sub_viewport：UI 内承载主世界画面的 SubViewport。它共享主场景 World2D，但必须使用自己的 Camera2D。
# - sub_viewport_camera：SubViewport 专属的镜像相机。它不参与主场景逻辑，只复制主 Camera2D 的视角。
# - source_world_camera：主场景真正用于跟随和边界计算的 Camera2D。
# - pause_menu_overlay：ESC 暂停菜单遮罩，包含继续游戏、设置、退出游戏。
# - pause_main_panel/settings_panel：暂停菜单的一级菜单和设置二级菜单。
# - input_preset_toggle_button：按键映射里的预设切换按钮，在手柄和键盘两套映射之间切换。
# - key_bind_rows：按键映射设置的动态行容器。每行由动作说明和当前按键按钮组成。
# - master/music/sfx_volume_slider：通过 SoundManager 写入 AudioServer 音频总线的音量滑杆。
# - active_input_preset：当前正在使用和编辑的输入预设。键盘、手柄两套绑定会分别保存。
# - waiting_rebind_action：当前正在等待改键的动作名。为空时表示没有改键捕获。
# - settings_config：把按键和音量保存到 user://settings.cfg，避免下次启动丢失。
# - active_reward_player_id：当前正在选择奖励的玩家编号。选择按钮发信号时会把这个编号传给主控制器。
# - active_reward_cards：当前显示的 3 张候选牌数据。选择按钮按索引从这里取出被选择的牌。
# - reward_choice_tween：奖励面板显示/隐藏动画的 Tween。它使用暂停无关模式，保证世界时停期间 UI 动画继续播放。
# - card_reward_selected(player_id, card_data)：玩家点选某张奖励牌时发出，主控制器收到后把牌加入对应玩家牌堆。
# - _ready()：缓存 tscn 中已经布好的 UI 节点，并设置初始提示为空。
# - _input(event)：处理 ESC 打开/关闭暂停菜单，并在改键模式下捕获下一次按键。
# - _process(delta)：每帧同步 SubViewport 的镜像相机，避免 UI 视口和主相机脱节。
# - initialize(world_camera)：接收主相机，把主场景 World2D 交给 SubViewport，并立即同步一次视角。
# - _sync_subviewport_camera()：复制主相机的位置、缩放和边界到 SubViewport 专属相机。
# - _set_pause_independent_ui_tree(node)：把 HUD 下的 UI 节点设为 Always，确保世界暂停时按钮和 UI 逻辑仍能响应。
# - create_pause_independent_tween()：创建不受 get_tree().paused 影响的 UI Tween，后续 HUD 动画统一走这个入口。
# - _open_pause_menu()/_resume_game()：打开暂停菜单和继续游戏。
# - _show_settings_panel()/_show_pause_main_panel()：在一级菜单和设置二级菜单之间切换。
# - _toggle_input_preset()：切换键盘/手柄输入预设，立即应用并保存当前预设类型。
# - _build_key_mapping_rows()：根据 REBIND_ACTIONS 创建按键映射 UI。
# - _start_rebinding(action_name)：进入某个动作的改键等待状态。
# - _apply_input_descriptor_binding(action_name, descriptor, should_save)：把当前预设的新输入写入 InputMap，并按需保存。
# - _apply_input_preset(preset_name, should_save)：应用某套输入预设，并刷新按钮显示。
# - _setup_audio_buses()：优先让 SoundManager 确保 Master/Music/SFX 三个音频总线存在。
# - _apply_audio_percent(bus_key, percent, should_save)：把滑杆百分比交给 SoundManager 写入实际音频总线。
# - _get_sound_manager()/_play_ui_sound(sound_name)：访问全局 SoundManager，并播放菜单反馈音。
# - _load_saved_settings()/_save_settings()：读取和保存玩家设置。
# - set_health(current_health, max_health)：更新醒目的血量条和血量文字。
# - set_link_state(is_active, seconds_left)：更新连线稳定或断线倒计时文字。
# - set_player_deck_status(player_id, card_name, card_count, cooldown_remaining)：更新指定玩家的当前牌、牌数和冷却状态。
# - set_message(message)：更新短消息区域，用于反馈任务点拾取和打牌结果。
# - set_game_result(message)：显示最终结果，并把结果同步到连线状态区域。
# - show_reward_choice(player_id, reward_cards)：显示任务点奖励面板，把 3 张候选牌渲染到按钮上。
# - hide_reward_choice()：隐藏任务点奖励面板并清空当前候选牌。
# - _play_reward_show_animation()/_play_reward_hide_animation()：播放奖励面板动画，动画不受世界时停影响。
# - _kill_reward_choice_tween()：切换奖励面板状态前停止旧动画，避免重复 Tween 抢同一属性。
# - _on_reward_button_pressed(index)：处理玩家点击第 index 个奖励按钮，发出 card_reward_selected 信号。
# - _format_reward_button_text(index, card_data)：把卡牌字典格式化成按钮上可读的三行文本。

signal card_reward_selected(player_id: int, card_data: Dictionary)

const SETTINGS_PATH := "user://settings.cfg"
const INPUT_PRESET_KEYBOARD := "keyboard"
const INPUT_PRESET_GAMEPAD := "gamepad"
const DEFAULT_INPUT_PRESET := INPUT_PRESET_GAMEPAD
const AUDIO_BUS_NAMES := {
	"master": "Master",
	"music": "Music",
	"sfx": "SFX",
}
const REBIND_ACTIONS := [
	{"action": "p1_move_left", "label": "P1 左移"},
	{"action": "p1_move_right", "label": "P1 右移"},
	{"action": "p1_move_up", "label": "P1 上移"},
	{"action": "p1_move_down", "label": "P1 下移"},
	{"action": "p1_play_card", "label": "P1 打出卡牌"},
	{"action": "p1_pass_card", "label": "P1 跳过卡牌"},
	{"action": "p2_move_left", "label": "P2 左移"},
	{"action": "p2_move_right", "label": "P2 右移"},
	{"action": "p2_move_up", "label": "P2 上移"},
	{"action": "p2_move_down", "label": "P2 下移"},
	{"action": "p2_play_card", "label": "P2 打出卡牌"},
	{"action": "p2_pass_card", "label": "P2 跳过卡牌"},
]
const INPUT_PRESET_LABELS := {
	INPUT_PRESET_KEYBOARD: "键盘",
	INPUT_PRESET_GAMEPAD: "手柄 Xbox / Nintendo",
}
const INPUT_PRESET_BINDING_SECTIONS := {
	INPUT_PRESET_KEYBOARD: "input_keyboard",
	INPUT_PRESET_GAMEPAD: "input_gamepad",
}
const DEFAULT_INPUT_PRESET_BINDINGS := {
	"keyboard": {
		"p1_move_left": [{"type": "key", "keycode": KEY_A}],
		"p1_move_right": [{"type": "key", "keycode": KEY_D}],
		"p1_move_up": [{"type": "key", "keycode": KEY_W}],
		"p1_move_down": [{"type": "key", "keycode": KEY_S}],
		"p1_play_card": [{"type": "key", "keycode": KEY_Q}],
		"p1_pass_card": [{"type": "key", "keycode": KEY_E}],
		"p2_move_left": [{"type": "key", "keycode": KEY_LEFT}],
		"p2_move_right": [{"type": "key", "keycode": KEY_RIGHT}],
		"p2_move_up": [{"type": "key", "keycode": KEY_UP}],
		"p2_move_down": [{"type": "key", "keycode": KEY_DOWN}],
		"p2_play_card": [{"type": "key", "keycode": KEY_K}],
		"p2_pass_card": [{"type": "key", "keycode": KEY_L}],
	},
	"gamepad": {
		"p1_move_left": [
			{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0},
			{"type": "joy_button", "button": JOY_BUTTON_DPAD_LEFT},
		],
		"p1_move_right": [
			{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0},
			{"type": "joy_button", "button": JOY_BUTTON_DPAD_RIGHT},
		],
		"p1_move_up": [
			{"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "value": -1.0},
			{"type": "joy_button", "button": JOY_BUTTON_DPAD_UP},
		],
		"p1_move_down": [
			{"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "value": 1.0},
			{"type": "joy_button", "button": JOY_BUTTON_DPAD_DOWN},
		],
		"p1_play_card": [{"type": "joy_button", "button": JOY_BUTTON_LEFT_SHOULDER}],
		"p1_pass_card": [{"type": "joy_button", "button": JOY_BUTTON_RIGHT_SHOULDER}],
		"p2_move_left": [{"type": "joy_axis", "axis": JOY_AXIS_RIGHT_X, "value": -1.0}],
		"p2_move_right": [{"type": "joy_axis", "axis": JOY_AXIS_RIGHT_X, "value": 1.0}],
		"p2_move_up": [{"type": "joy_axis", "axis": JOY_AXIS_RIGHT_Y, "value": -1.0}],
		"p2_move_down": [{"type": "joy_axis", "axis": JOY_AXIS_RIGHT_Y, "value": 1.0}],
		"p2_play_card": [{"type": "joy_button", "button": JOY_BUTTON_X}],
		"p2_pass_card": [{"type": "joy_button", "button": JOY_BUTTON_Y}],
	},
}

@onready var sub_viewport: SubViewport = $Root/SubViewportContainer/SubViewport
@onready var sub_viewport_camera: Camera2D = $Root/SubViewportContainer/SubViewport/ViewportCamera2D
@onready var health_label: Label = $Root/TopStrip/HealthLabel
@onready var health_bar: ProgressBar = $Root/TopStrip/HealthBar
@onready var link_status_label: Label = $Root/TopStrip/LinkStatusLabel
@onready var death_countdown_panel: Control = $Root/DeathCountdownPanel
@onready var death_countdown_label: Label = $Root/DeathCountdownPanel/DeathCountdownLabel
@onready var player_one_card_label: Label = $Root/PlayerOnePanel/CardLabel
@onready var player_two_card_label: Label = $Root/PlayerTwoPanel/CardLabel
@onready var player_one_count_label: Label = $Root/PlayerOnePanel/CountLabel
@onready var player_two_count_label: Label = $Root/PlayerTwoPanel/CountLabel
@onready var message_label: Label = $Root/MessageLabel
@onready var reward_choice_overlay: Control = $Root/RewardChoiceOverlay
@onready var reward_choice_panel: Panel = $Root/RewardChoiceOverlay/Panel
@onready var reward_title_label: Label = $Root/RewardChoiceOverlay/Panel/TitleLabel
@onready var reward_hint_label: Label = $Root/RewardChoiceOverlay/Panel/HintLabel
@onready var reward_choice_buttons: Array[Button] = [
	$Root/RewardChoiceOverlay/Panel/ChoiceOneButton,
	$Root/RewardChoiceOverlay/Panel/ChoiceTwoButton,
	$Root/RewardChoiceOverlay/Panel/ChoiceThreeButton,
]
@onready var pause_menu_overlay: ColorRect = $Root/PauseMenuOverlay
@onready var pause_main_panel: Panel = $Root/PauseMenuOverlay/MainPanel
@onready var settings_panel: Panel = $Root/PauseMenuOverlay/SettingsPanel
@onready var continue_button: Button = $Root/PauseMenuOverlay/MainPanel/ContinueButton
@onready var settings_button: Button = $Root/PauseMenuOverlay/MainPanel/SettingsButton
@onready var quit_button: Button = $Root/PauseMenuOverlay/MainPanel/QuitButton
@onready var settings_back_button: Button = $Root/PauseMenuOverlay/SettingsPanel/BackButton
@onready var input_preset_toggle_button: Button = $Root/PauseMenuOverlay/SettingsPanel/SettingsScroll/SettingsContent/KeyMappingSection/InputPresetRow/InputPresetToggleButton
@onready var key_bind_rows: VBoxContainer = $Root/PauseMenuOverlay/SettingsPanel/SettingsScroll/SettingsContent/KeyMappingSection/KeyBindRows
@onready var master_volume_slider: HSlider = $Root/PauseMenuOverlay/SettingsPanel/SettingsScroll/SettingsContent/AudioSection/MasterVolumeRow/MasterVolumeSlider
@onready var music_volume_slider: HSlider = $Root/PauseMenuOverlay/SettingsPanel/SettingsScroll/SettingsContent/AudioSection/MusicVolumeRow/MusicVolumeSlider
@onready var sfx_volume_slider: HSlider = $Root/PauseMenuOverlay/SettingsPanel/SettingsScroll/SettingsContent/AudioSection/SfxVolumeRow/SfxVolumeSlider
@onready var master_volume_value_label: Label = $Root/PauseMenuOverlay/SettingsPanel/SettingsScroll/SettingsContent/AudioSection/MasterVolumeRow/MasterVolumeValueLabel
@onready var music_volume_value_label: Label = $Root/PauseMenuOverlay/SettingsPanel/SettingsScroll/SettingsContent/AudioSection/MusicVolumeRow/MusicVolumeValueLabel
@onready var sfx_volume_value_label: Label = $Root/PauseMenuOverlay/SettingsPanel/SettingsScroll/SettingsContent/AudioSection/SfxVolumeRow/SfxVolumeValueLabel
@onready var rebind_hint_label: Label = $Root/PauseMenuOverlay/SettingsPanel/RebindHintLabel

var active_reward_player_id := 0
var active_reward_cards: Array = []
var reward_choice_tween: Tween
var source_world_camera: Camera2D
var active_input_preset := DEFAULT_INPUT_PRESET
var waiting_rebind_action := StringName()
var rebind_buttons_by_action := {}
var settings_config := ConfigFile.new()
var audio_sliders_connected := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_pause_independent_ui_tree(self)
	set_message("")
	death_countdown_panel.visible = false
	hide_reward_choice(false)
	_hide_pause_menu_without_unpausing()
	for index in reward_choice_buttons.size():
		reward_choice_buttons[index].pressed.connect(_on_reward_button_pressed.bind(index))
	continue_button.pressed.connect(_resume_game)
	settings_button.pressed.connect(_show_settings_panel)
	quit_button.pressed.connect(_quit_game)
	settings_back_button.pressed.connect(_show_pause_main_panel)
	input_preset_toggle_button.pressed.connect(_toggle_input_preset)
	_setup_audio_buses()
	_build_key_mapping_rows()
	_setup_audio_sliders()
	_update_input_preset_button()
	_refresh_rebind_buttons()


func _input(event: InputEvent) -> void:
	if waiting_rebind_action != StringName():
		if event is InputEventKey and _get_keycode_from_event(event as InputEventKey) == KEY_ESCAPE:
			_cancel_rebinding()
		else:
			var descriptor := _make_descriptor_from_rebind_event(event)
			if descriptor.is_empty():
				return
			_apply_input_descriptor_binding(waiting_rebind_action, descriptor, true)
			waiting_rebind_action = StringName()
			rebind_hint_label.text = "输入已更新"
		get_viewport().set_input_as_handled()
		return

	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var physical_keycode := _get_keycode_from_event(key_event)

	if physical_keycode == KEY_ESCAPE:
		_handle_escape_pressed()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	_sync_subviewport_camera()


func initialize(world_camera: Camera2D) -> void:
	source_world_camera = world_camera
	sub_viewport.world_2d = source_world_camera.get_viewport().world_2d
	sub_viewport_camera.make_current()
	_sync_subviewport_camera()
	_load_saved_settings()
	_connect_audio_sliders()
	_refresh_rebind_buttons()


func _sync_subviewport_camera() -> void:
	if not is_instance_valid(source_world_camera):
		return

	sub_viewport_camera.global_position = source_world_camera.global_position
	sub_viewport_camera.rotation = source_world_camera.rotation
	sub_viewport_camera.zoom = source_world_camera.zoom
	sub_viewport_camera.offset = source_world_camera.offset
	sub_viewport_camera.limit_left = source_world_camera.limit_left
	sub_viewport_camera.limit_top = source_world_camera.limit_top
	sub_viewport_camera.limit_right = source_world_camera.limit_right
	sub_viewport_camera.limit_bottom = source_world_camera.limit_bottom
	sub_viewport_camera.enabled = true


func _set_pause_independent_ui_tree(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_set_pause_independent_ui_tree(child)


func create_pause_independent_tween() -> Tween:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return tween


func _handle_escape_pressed() -> void:
	if reward_choice_overlay.visible:
		return

	if pause_menu_overlay.visible:
		if settings_panel.visible:
			_show_pause_main_panel()
		else:
			_resume_game()
	else:
		_open_pause_menu()


func _open_pause_menu() -> void:
	waiting_rebind_action = StringName()
	rebind_hint_label.text = ""
	pause_menu_overlay.visible = true
	_show_pause_main_panel(false)
	get_tree().paused = true
	continue_button.grab_focus()
	_play_ui_sound(&"pause_start")


func _resume_game() -> void:
	_hide_pause_menu_without_unpausing()
	get_tree().paused = false
	_play_ui_sound(&"pause_end")


func _hide_pause_menu_without_unpausing() -> void:
	waiting_rebind_action = StringName()
	pause_menu_overlay.visible = false
	pause_main_panel.visible = true
	settings_panel.visible = false
	if is_instance_valid(rebind_hint_label):
		rebind_hint_label.text = ""


func _show_pause_main_panel(play_sound := true) -> void:
	waiting_rebind_action = StringName()
	rebind_hint_label.text = ""
	pause_main_panel.visible = true
	settings_panel.visible = false
	continue_button.grab_focus()
	_refresh_rebind_buttons()
	if play_sound and pause_menu_overlay.visible:
		_play_ui_sound(&"menu_previous")


func _show_settings_panel() -> void:
	pause_main_panel.visible = false
	settings_panel.visible = true
	settings_back_button.grab_focus()
	_update_input_preset_button()
	_refresh_rebind_buttons()
	_play_ui_sound(&"menu_next")


func _quit_game() -> void:
	_play_ui_sound(&"menu_unload")
	get_tree().quit()


func _toggle_input_preset() -> void:
	var next_preset := INPUT_PRESET_KEYBOARD
	if active_input_preset == INPUT_PRESET_KEYBOARD:
		next_preset = INPUT_PRESET_GAMEPAD

	_apply_input_preset(next_preset, true)
	rebind_hint_label.text = "已切换到%s预设" % INPUT_PRESET_LABELS[active_input_preset]
	_play_ui_sound(&"menu_next")


func _build_key_mapping_rows() -> void:
	rebind_buttons_by_action.clear()
	for action_info in REBIND_ACTIONS:
		var action_name := StringName(action_info["action"])
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0.0, 34.0)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 14)

		var action_label := Label.new()
		action_label.text = action_info["label"]
		action_label.custom_minimum_size = Vector2(190.0, 30.0)
		action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(action_label)

		var key_button := Button.new()
		key_button.custom_minimum_size = Vector2(170.0, 30.0)
		key_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_button.pressed.connect(_start_rebinding.bind(action_name))
		row.add_child(key_button)

		key_bind_rows.add_child(row)
		rebind_buttons_by_action[action_name] = key_button


func _start_rebinding(action_name: StringName) -> void:
	waiting_rebind_action = action_name
	if active_input_preset == INPUT_PRESET_GAMEPAD:
		rebind_hint_label.text = "按下手柄按钮或推动摇杆，ESC 取消"
	else:
		rebind_hint_label.text = "按下新按键，ESC 取消"
	_refresh_rebind_buttons()
	_play_ui_sound(&"menu_equip")


func _cancel_rebinding() -> void:
	waiting_rebind_action = StringName()
	rebind_hint_label.text = "已取消改键"
	_refresh_rebind_buttons()
	_play_ui_sound(&"menu_unload")


func _refresh_rebind_buttons() -> void:
	_update_input_preset_button()
	for action_info in REBIND_ACTIONS:
		var action_name := StringName(action_info["action"])
		if not rebind_buttons_by_action.has(action_name):
			continue

		var key_button: Button = rebind_buttons_by_action[action_name]
		if waiting_rebind_action == action_name:
			if active_input_preset == INPUT_PRESET_GAMEPAD:
				key_button.text = "等待手柄输入..."
			else:
				key_button.text = "等待按键..."
		else:
			key_button.text = _get_action_key_text(action_name)


func _update_input_preset_button() -> void:
	if not is_instance_valid(input_preset_toggle_button):
		return

	var current_label: String = INPUT_PRESET_LABELS.get(active_input_preset, "未知")
	var next_label := "键盘"
	if active_input_preset == INPUT_PRESET_KEYBOARD:
		next_label = "手柄 Xbox / Nintendo"
	input_preset_toggle_button.text = "当前：%s    切换到：%s" % [current_label, next_label]


func _get_action_key_text(action_name: StringName) -> String:
	if not InputMap.has_action(action_name):
		return "未设置"

	var event_texts: Array[String] = []
	for input_event in InputMap.action_get_events(action_name):
		var event_text := _get_input_event_text(input_event)
		if not event_text.is_empty():
			event_texts.append(event_text)
	if event_texts.is_empty():
		return "未设置"
	return _join_texts(event_texts, " / ")


func _get_input_event_text(input_event: InputEvent) -> String:
	if input_event is InputEventKey:
		var keycode := _get_keycode_from_event(input_event as InputEventKey)
		var key_text := OS.get_keycode_string(keycode)
		if key_text.is_empty():
			key_text = input_event.as_text()
		return key_text

	if input_event is InputEventJoypadButton:
		return _get_joy_button_text((input_event as InputEventJoypadButton).button_index)

	if input_event is InputEventJoypadMotion:
		var motion_event := input_event as InputEventJoypadMotion
		return _get_joy_axis_text(motion_event.axis, motion_event.axis_value)

	return "未设置"


func _join_texts(texts: Array[String], separator: String) -> String:
	var joined := ""
	for index in texts.size():
		if index > 0:
			joined += separator
		joined += texts[index]
	return joined


func _apply_input_descriptor_binding(action_name: StringName, descriptor: Dictionary, should_save: bool) -> void:
	if descriptor.is_empty():
		return
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)

	_erase_action_events(action_name)
	var input_event = _make_input_event_from_descriptor(descriptor)
	if input_event == null:
		return

	InputMap.action_add_event(action_name, input_event)

	if should_save:
		settings_config.set_value(_get_input_preset_section(active_input_preset), String(action_name), [descriptor])
		_save_settings()
		_play_ui_sound(&"upgrade_ui_selected")
	_refresh_rebind_buttons()


func _apply_keycode_binding(action_name: StringName, keycode: int, should_save: bool) -> void:
	_apply_input_descriptor_binding(action_name, {"type": "key", "keycode": keycode}, should_save)


func _apply_input_preset(preset_name: String, should_save: bool) -> void:
	active_input_preset = _normalize_input_preset(preset_name)
	waiting_rebind_action = StringName()

	for action_info in REBIND_ACTIONS:
		var action_name := StringName(action_info["action"])
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name, 0.2)

		_erase_action_events(action_name)
		for descriptor in _get_input_descriptors_for_action(action_name, active_input_preset):
			var input_event = _make_input_event_from_descriptor(descriptor)
			if input_event != null:
				InputMap.action_add_event(action_name, input_event)

	if should_save:
		settings_config.set_value("input", "active_preset", active_input_preset)
		_save_settings()

	_update_input_preset_button()
	_refresh_rebind_buttons()


func _erase_action_events(action_name: StringName) -> void:
	for input_event in InputMap.action_get_events(action_name):
		InputMap.action_erase_event(action_name, input_event)


func _get_input_descriptors_for_action(action_name: StringName, preset_name: String) -> Array:
	var section_name := _get_input_preset_section(preset_name)
	var action_key := String(action_name)
	if settings_config.has_section_key(section_name, action_key):
		return _normalize_descriptor_array(settings_config.get_value(section_name, action_key, []))

	var preset_bindings: Dictionary = DEFAULT_INPUT_PRESET_BINDINGS.get(preset_name, {})
	return _normalize_descriptor_array(preset_bindings.get(action_key, []))


func _normalize_descriptor_array(value) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	if value is Dictionary:
		return [(value as Dictionary).duplicate(true)]
	if typeof(value) == TYPE_INT:
		return [{"type": "key", "keycode": int(value)}]
	return []


func _get_input_preset_section(preset_name: String) -> String:
	return INPUT_PRESET_BINDING_SECTIONS.get(_normalize_input_preset(preset_name), "input_gamepad")


func _normalize_input_preset(preset_name: String) -> String:
	if preset_name == INPUT_PRESET_KEYBOARD:
		return INPUT_PRESET_KEYBOARD
	return INPUT_PRESET_GAMEPAD


func _make_input_event_from_descriptor(descriptor: Dictionary):
	var descriptor_type := String(descriptor.get("type", ""))
	if descriptor_type == "key":
		var keycode := int(descriptor.get("keycode", KEY_NONE))
		if keycode == KEY_NONE:
			return null
		var key_event := InputEventKey.new()
		key_event.physical_keycode = keycode
		return key_event

	if descriptor_type == "joy_button":
		var button_event := InputEventJoypadButton.new()
		button_event.button_index = int(descriptor.get("button", JOY_BUTTON_INVALID))
		return button_event

	if descriptor_type == "joy_axis":
		var axis_event := InputEventJoypadMotion.new()
		axis_event.axis = int(descriptor.get("axis", JOY_AXIS_INVALID))
		axis_event.axis_value = signf(float(descriptor.get("value", 1.0)))
		return axis_event

	return null


func _make_descriptor_from_rebind_event(event: InputEvent) -> Dictionary:
	if active_input_preset == INPUT_PRESET_KEYBOARD:
		if not event is InputEventKey:
			return {}
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return {}
		var keycode := _get_keycode_from_event(key_event)
		if keycode == KEY_NONE:
			return {}
		return {"type": "key", "keycode": keycode}

	if event is InputEventJoypadButton:
		var button_event := event as InputEventJoypadButton
		if not button_event.pressed:
			return {}
		return {"type": "joy_button", "button": button_event.button_index}

	if event is InputEventJoypadMotion:
		var motion_event := event as InputEventJoypadMotion
		if absf(motion_event.axis_value) < 0.55:
			return {}
		return {
			"type": "joy_axis",
			"axis": motion_event.axis,
			"value": signf(motion_event.axis_value),
		}

	return {}


func _get_keycode_from_event(key_event: InputEventKey) -> int:
	var keycode := key_event.physical_keycode
	if keycode == KEY_NONE:
		keycode = key_event.keycode
	return keycode


func _get_joy_button_text(button_index: int) -> String:
	if button_index == JOY_BUTTON_A:
		return "Xbox A / Nintendo B"
	if button_index == JOY_BUTTON_B:
		return "Xbox B / Nintendo A"
	if button_index == JOY_BUTTON_X:
		return "Xbox X / Nintendo Y"
	if button_index == JOY_BUTTON_Y:
		return "Xbox Y / Nintendo X"
	if button_index == JOY_BUTTON_LEFT_SHOULDER:
		return "LB / L"
	if button_index == JOY_BUTTON_RIGHT_SHOULDER:
		return "RB / R"
	if button_index == JOY_BUTTON_DPAD_LEFT:
		return "十字左"
	if button_index == JOY_BUTTON_DPAD_RIGHT:
		return "十字右"
	if button_index == JOY_BUTTON_DPAD_UP:
		return "十字上"
	if button_index == JOY_BUTTON_DPAD_DOWN:
		return "十字下"
	return "手柄按钮 %d" % button_index


func _get_joy_axis_text(axis: int, axis_value: float) -> String:
	if axis == JOY_AXIS_LEFT_X:
		if axis_value < 0.0:
			return "左摇杆左"
		return "左摇杆右"
	if axis == JOY_AXIS_LEFT_Y:
		if axis_value < 0.0:
			return "左摇杆上"
		return "左摇杆下"
	if axis == JOY_AXIS_RIGHT_X:
		if axis_value < 0.0:
			return "右摇杆左"
		return "右摇杆右"
	if axis == JOY_AXIS_RIGHT_Y:
		if axis_value < 0.0:
			return "右摇杆上"
		return "右摇杆下"
	return "手柄轴 %d %+.0f" % [axis, signf(axis_value)]


func _setup_audio_buses() -> void:
	var sound_manager := _get_sound_manager()
	if sound_manager != null and sound_manager.has_method("setup_audio_buses"):
		sound_manager.call("setup_audio_buses")
		return

	_ensure_audio_bus("Master")
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	var bus_index := AudioServer.bus_count
	AudioServer.add_bus(bus_index)
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _setup_audio_sliders() -> void:
	for slider in [master_volume_slider, music_volume_slider, sfx_volume_slider]:
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 1.0
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	master_volume_slider.value = _get_audio_percent("master")
	music_volume_slider.value = _get_audio_percent("music")
	sfx_volume_slider.value = _get_audio_percent("sfx")
	_update_audio_value_label("master", master_volume_slider.value)
	_update_audio_value_label("music", music_volume_slider.value)
	_update_audio_value_label("sfx", sfx_volume_slider.value)


func _connect_audio_sliders() -> void:
	if audio_sliders_connected:
		return

	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	audio_sliders_connected = true


func _on_master_volume_changed(value: float) -> void:
	_apply_audio_percent("master", value, true)


func _on_music_volume_changed(value: float) -> void:
	_apply_audio_percent("music", value, true)


func _on_sfx_volume_changed(value: float) -> void:
	_apply_audio_percent("sfx", value, true)


func _get_audio_percent(bus_key: String) -> float:
	var sound_manager := _get_sound_manager()
	if sound_manager != null and sound_manager.has_method("get_volume_percent"):
		return float(sound_manager.call("get_volume_percent", StringName(bus_key)))

	var bus_name: String = AUDIO_BUS_NAMES[bus_key]
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1 or AudioServer.is_bus_mute(bus_index):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)) * 100.0, 0.0, 100.0)


func _apply_audio_percent(bus_key: String, percent: float, should_save: bool) -> void:
	var clamped_percent := clampf(percent, 0.0, 100.0)
	var sound_manager := _get_sound_manager()
	if sound_manager != null and sound_manager.has_method("set_volume_percent"):
		sound_manager.call("set_volume_percent", StringName(bus_key), clamped_percent)
	else:
		var bus_name: String = AUDIO_BUS_NAMES[bus_key]
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index != -1:
			if clamped_percent <= 0.0:
				AudioServer.set_bus_mute(bus_index, true)
				AudioServer.set_bus_volume_db(bus_index, -80.0)
			else:
				AudioServer.set_bus_mute(bus_index, false)
				AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped_percent / 100.0))

	_update_audio_value_label(bus_key, clamped_percent)
	if should_save:
		settings_config.set_value("audio", bus_key, clamped_percent)
		_save_settings()


func _get_sound_manager() -> Node:
	return get_node_or_null("/root/SoundManager")


func _play_ui_sound(sound_name: StringName) -> void:
	var sound_manager := _get_sound_manager()
	if sound_manager != null and sound_manager.has_method("has_sound") and not bool(sound_manager.call("has_sound", sound_name)):
		return
	if sound_manager != null and sound_manager.has_method("play"):
		sound_manager.call("play", sound_name)


func _update_audio_value_label(bus_key: String, percent: float) -> void:
	var label := master_volume_value_label
	if bus_key == "music":
		label = music_volume_value_label
	elif bus_key == "sfx":
		label = sfx_volume_value_label
	label.text = "%d%%" % roundi(percent)


func _load_saved_settings() -> void:
	var load_error := settings_config.load(SETTINGS_PATH)
	if load_error == OK:
		_migrate_legacy_keyboard_settings()
		active_input_preset = _normalize_input_preset(String(settings_config.get_value("input", "active_preset", DEFAULT_INPUT_PRESET)))
	else:
		active_input_preset = DEFAULT_INPUT_PRESET

	_apply_input_preset(active_input_preset, false)

	for bus_key in AUDIO_BUS_NAMES.keys():
		if settings_config.has_section_key("audio", bus_key):
			var percent := float(settings_config.get_value("audio", bus_key, _get_audio_percent(bus_key)))
			_set_audio_slider_value(bus_key, percent)
			_apply_audio_percent(bus_key, percent, false)


func _migrate_legacy_keyboard_settings() -> void:
	for action_info in REBIND_ACTIONS:
		var action_key := String(action_info["action"])
		if not settings_config.has_section_key("input", action_key):
			continue
		if settings_config.has_section_key("input_keyboard", action_key):
			continue

		var keycode := int(settings_config.get_value("input", action_key, KEY_NONE))
		if keycode != KEY_NONE:
			settings_config.set_value("input_keyboard", action_key, [{"type": "key", "keycode": keycode}])


func _set_audio_slider_value(bus_key: String, percent: float) -> void:
	if bus_key == "master":
		master_volume_slider.value = percent
	elif bus_key == "music":
		music_volume_slider.value = percent
	elif bus_key == "sfx":
		sfx_volume_slider.value = percent


func _save_settings() -> void:
	var save_error := settings_config.save(SETTINGS_PATH)
	if save_error != OK:
		set_message("设置保存失败")


func set_health(current_health: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "HP %d / %d" % [roundi(current_health), roundi(max_health)]


func set_link_state(is_active: bool, seconds_left: float) -> void:
	if is_active:
		link_status_label.text = "连线稳定"
		death_countdown_panel.visible = false
	else:
		var clamped_seconds: float = maxf(0.0, seconds_left)
		link_status_label.text = "断线 %.1fs" % clamped_seconds
		death_countdown_label.text = "死亡倒计时 %.1f" % clamped_seconds
		death_countdown_panel.visible = true


func set_player_deck_status(player_id: int, card_name: String, card_count: int, cooldown_remaining: float) -> void:
	var cooldown_text := ""
	if cooldown_remaining > 0.0:
		cooldown_text = "  %.1fs" % cooldown_remaining

	if player_id == 1:
		player_one_card_label.text = "P1  %s%s" % [card_name, cooldown_text]
		player_one_count_label.text = "牌堆 %d" % card_count
	elif player_id == 2:
		player_two_card_label.text = "P2  %s%s" % [card_name, cooldown_text]
		player_two_count_label.text = "牌堆 %d" % card_count


func set_message(message: String) -> void:
	message_label.text = message


func set_game_result(message: String) -> void:
	link_status_label.text = message
	message_label.text = message
	death_countdown_panel.visible = false


func show_reward_choice(player_id: int, reward_cards: Array) -> void:
	active_reward_player_id = player_id
	active_reward_cards = reward_cards.duplicate(true)
	reward_title_label.text = "P%d 任务点奖励" % player_id
	reward_hint_label.text = "选择 1 张牌加入 P%d 的牌堆" % player_id
	for index in reward_choice_buttons.size():
		var has_card := index < active_reward_cards.size()
		reward_choice_buttons[index].visible = has_card
		reward_choice_buttons[index].disabled = not has_card
		if has_card:
			reward_choice_buttons[index].text = _format_reward_button_text(index, active_reward_cards[index])
	reward_choice_overlay.visible = true
	_play_reward_show_animation()
	if not reward_choice_buttons.is_empty() and reward_choice_buttons[0].visible:
		reward_choice_buttons[0].grab_focus()


func hide_reward_choice(animate := true) -> void:
	var was_visible := reward_choice_overlay.visible
	active_reward_player_id = 0
	active_reward_cards.clear()
	if not animate or not was_visible:
		_kill_reward_choice_tween()
		reward_choice_overlay.visible = false
		reward_choice_overlay.modulate.a = 1.0
		reward_choice_panel.scale = Vector2.ONE
		return

	_play_reward_hide_animation()


func _play_reward_show_animation() -> void:
	_kill_reward_choice_tween()
	reward_choice_overlay.modulate.a = 0.0
	reward_choice_panel.scale = Vector2(0.96, 0.96)
	reward_choice_panel.pivot_offset = reward_choice_panel.size * 0.5
	reward_choice_tween = create_pause_independent_tween()
	reward_choice_tween.set_parallel(true)
	reward_choice_tween.tween_property(reward_choice_overlay, "modulate:a", 1.0, 0.12)
	reward_choice_tween.tween_property(reward_choice_panel, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_reward_hide_animation() -> void:
	_kill_reward_choice_tween()
	reward_choice_panel.pivot_offset = reward_choice_panel.size * 0.5
	reward_choice_tween = create_pause_independent_tween()
	reward_choice_tween.set_parallel(true)
	reward_choice_tween.tween_property(reward_choice_overlay, "modulate:a", 0.0, 0.10)
	reward_choice_tween.tween_property(reward_choice_panel, "scale", Vector2(0.98, 0.98), 0.10)
	reward_choice_tween.finished.connect(func() -> void:
		reward_choice_overlay.visible = false
		reward_choice_overlay.modulate.a = 1.0
		reward_choice_panel.scale = Vector2.ONE
		reward_choice_tween = null
	)


func _kill_reward_choice_tween() -> void:
	if reward_choice_tween != null and reward_choice_tween.is_valid():
		reward_choice_tween.kill()
	reward_choice_tween = null


func _on_reward_button_pressed(index: int) -> void:
	if index < 0 or index >= active_reward_cards.size():
		return

	var selected_card: Dictionary = active_reward_cards[index].duplicate(true)
	card_reward_selected.emit(active_reward_player_id, selected_card)


func _format_reward_button_text(index: int, card_data: Dictionary) -> String:
	var type_text := "其他牌"
	if card_data.get("type", "") == "attack":
		type_text = "攻击牌"
	return "%d. %s\n%s\n%s" % [
		index + 1,
		card_data.get("name", "未命名牌"),
		type_text,
		card_data.get("description", ""),
	]
