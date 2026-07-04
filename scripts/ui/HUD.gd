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
# - pause_menu_overlay：暂停菜单遮罩，包含继续游戏、设置、退出游戏。
# - pause_main_panel/settings_panel：暂停菜单的一级菜单和设置二级菜单。
# - game_over_overlay：死亡动画结束后出现的全屏黑幕，盖住 SubViewport 和所有运行时 UI。
# - game_over_title_label/game_over_reason_label：Gameover 标题和失败原因文本。
# - game_over_try_again_button：Try again 按钮。按下后发出 try_again_requested，由 GameController 重置世界状态。
# - game_over_tween：Gameover 黑幕淡入/淡出动画，使用暂停无关模式，每段默认 3 秒。
# - settings_scroll：设置二级菜单里的滚动区域，手柄右摇杆上下会直接滚动它。
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
# - try_again_requested()：玩家在 Gameover 黑幕上按下 Try again 时发出，主控制器负责重置游戏状态。
# - game_over_cover_shown()：黑幕淡入完成且 Try again 可用时发出，便于测试和后续音效/动画衔接。
# - restart_fade_finished()：Try again 后黑幕淡出完成时发出，主控制器收到后重新开放玩家控制。
# - _ready()：缓存 tscn 中已经布好的 UI 节点，并设置初始提示为空。
# - _input(event)：处理菜单/暂停输入打开或关闭暂停菜单，并在改键模式下捕获下一次按键。
# - _process(delta)：每帧同步 SubViewport 的镜像相机，并在设置面板打开时读取右摇杆滚动 SettingsScroll。
# - initialize(world_camera)：接收主相机，把主场景 World2D 交给 SubViewport，并立即同步一次视角。
# - _sync_subviewport_camera()：复制主相机的位置、缩放和边界到 SubViewport 专属相机。
# - _set_pause_independent_ui_tree(node)：把 HUD 下的 UI 节点设为 Always，确保世界暂停时按钮和 UI 逻辑仍能响应。
# - create_pause_independent_tween()：创建不受 get_tree().paused 影响的 UI Tween，后续 HUD 动画统一走这个入口。
# - _handle_pause_menu_pressed()/_open_pause_menu()/_resume_game()：打开暂停菜单和继续游戏。
# - _build_game_over_overlay()：运行时创建 Gameover 黑幕，避免修改 MainScene。
# - show_game_over(reason, fade_seconds)：死亡动画结束后播放 3 秒黑幕淡入，并显示 Gameover 和 Try again。
# - fade_out_game_over_after_restart(fade_seconds)：主控制器重置完世界后播放 3 秒黑幕淡出。
# - reset_runtime_ui_for_restart()：Try again 时清理奖励、暂停、倒计时和消息，不触碰设置。
# - _update_settings_scroll_gamepad(delta)：设置面板打开时，读取任意手柄右摇杆上下滚动 SettingsScroll。
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
signal try_again_requested
signal game_over_cover_shown
signal restart_fade_finished

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_GAME_OVER_FADE_SECONDS := 3.0
const INPUT_PRESET_KEYBOARD := "keyboard"
const INPUT_PRESET_GAMEPAD := "gamepad"
const DEFAULT_INPUT_PRESET := INPUT_PRESET_GAMEPAD
const ACTION_PAUSE_MENU := "pause_menu"
const SETTINGS_SCROLL_RIGHT_STICK_DEADZONE := 0.25
const SETTINGS_SCROLL_RIGHT_STICK_SPEED := 900.0
const AUDIO_BUS_NAMES := {
	"master": "Master",
	"music": "Music",
	"sfx": "SFX",
}
const REBIND_ACTIONS := [
	{"action": ACTION_PAUSE_MENU, "label": "菜单 / 暂停"},
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
		"pause_menu": [{"type": "key", "keycode": KEY_ESCAPE}],
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
		"pause_menu": [{"type": "joy_button", "button": JOY_BUTTON_START}],
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
		"p2_move_left": [
			{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0},
			{"type": "joy_button", "button": JOY_BUTTON_DPAD_LEFT},
		],
		"p2_move_right": [
			{"type": "joy_axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0},
			{"type": "joy_button", "button": JOY_BUTTON_DPAD_RIGHT},
		],
		"p2_move_up": [
			{"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "value": -1.0},
			{"type": "joy_button", "button": JOY_BUTTON_DPAD_UP},
		],
		"p2_move_down": [
			{"type": "joy_axis", "axis": JOY_AXIS_LEFT_Y, "value": 1.0},
			{"type": "joy_button", "button": JOY_BUTTON_DPAD_DOWN},
		],
		"p2_play_card": [{"type": "joy_button", "button": JOY_BUTTON_LEFT_SHOULDER}],
		"p2_pass_card": [{"type": "joy_button", "button": JOY_BUTTON_RIGHT_SHOULDER}],
	},
}

@onready var root: Control = $Root
@onready var sub_viewport: SubViewport = $Root/SubViewportContainer/SubViewport
@onready var sub_viewport_camera: Camera2D = $Root/SubViewportContainer/SubViewport/ViewportCamera2D
@onready var health_bar: TextureProgressBar = $Root/HealthBar
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
@onready var settings_scroll: ScrollContainer = $Root/PauseMenuOverlay/SettingsPanel/SettingsScroll
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
var game_over_overlay: ColorRect
var game_over_title_label: Label
var game_over_reason_label: Label
var game_over_try_again_button: Button
var game_over_tween: Tween
var source_world_camera: Camera2D
var active_input_preset := DEFAULT_INPUT_PRESET
var waiting_rebind_action := StringName()
var rebind_buttons_by_action := {}
var settings_config := ConfigFile.new()
var audio_sliders_connected := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_pause_independent_ui_tree(self)
	_ensure_pause_menu_action_defaults()
	_build_game_over_overlay()
	set_message("")
	death_countdown_panel.visible = false
	hide_reward_choice(false)
	_hide_pause_menu_without_unpausing()
	_hide_game_over_overlay_without_signal()
	for index in reward_choice_buttons.size():
		reward_choice_buttons[index].pressed.connect(_on_reward_button_pressed.bind(index))
	continue_button.pressed.connect(_resume_game)
	settings_button.pressed.connect(_show_settings_panel)
	quit_button.pressed.connect(_quit_game)
	settings_back_button.pressed.connect(_show_pause_main_panel)
	input_preset_toggle_button.pressed.connect(_toggle_input_preset)
	game_over_try_again_button.pressed.connect(_on_try_again_button_pressed)
	_setup_audio_buses()
	_build_key_mapping_rows()
	_setup_audio_sliders()
	_update_input_preset_button()
	_refresh_rebind_buttons()


func _input(event: InputEvent) -> void:
	if waiting_rebind_action != StringName():
		if _is_pause_menu_event(event):
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

	if game_over_overlay != null and game_over_overlay.visible:
		return

	if _is_pause_menu_event(event):
		_handle_pause_menu_pressed()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_sync_subviewport_camera()
	_update_settings_scroll_gamepad(delta)


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


func _handle_pause_menu_pressed() -> void:
	if game_over_overlay != null and game_over_overlay.visible:
		return
	if reward_choice_overlay.visible:
		return

	if pause_menu_overlay.visible:
		if settings_panel.visible:
			_show_pause_main_panel()
		else:
			_resume_game()
	else:
		_open_pause_menu()


func _build_game_over_overlay() -> void:
	if game_over_overlay != null:
		return

	game_over_overlay = ColorRect.new()
	game_over_overlay.name = "GameOverOverlay"
	game_over_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.grow_horizontal = Control.GROW_DIRECTION_BOTH
	game_over_overlay.grow_vertical = Control.GROW_DIRECTION_BOTH
	game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_overlay.color = Color.BLACK
	game_over_overlay.visible = false
	root.add_child(game_over_overlay)

	var content := VBoxContainer.new()
	content.name = "GameOverContent"
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -270.0
	content.offset_top = -126.0
	content.offset_right = 270.0
	content.offset_bottom = 170.0
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 22)
	game_over_overlay.add_child(content)

	game_over_title_label = Label.new()
	game_over_title_label.name = "GameOverTitleLabel"
	game_over_title_label.text = "Gameover"
	game_over_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_over_title_label.custom_minimum_size = Vector2(540.0, 82.0)
	game_over_title_label.add_theme_font_size_override("font_size", 72)
	game_over_title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	game_over_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	game_over_title_label.add_theme_constant_override("shadow_offset_x", 4)
	game_over_title_label.add_theme_constant_override("shadow_offset_y", 4)
	content.add_child(game_over_title_label)

	game_over_reason_label = Label.new()
	game_over_reason_label.name = "GameOverReasonLabel"
	game_over_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_reason_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_reason_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_over_reason_label.custom_minimum_size = Vector2(540.0, 34.0)
	game_over_reason_label.add_theme_font_size_override("font_size", 24)
	game_over_reason_label.add_theme_color_override("font_color", Color(0.82, 0.84, 0.88, 1.0))
	content.add_child(game_over_reason_label)

	game_over_try_again_button = Button.new()
	game_over_try_again_button.name = "TryAgainButton"
	game_over_try_again_button.text = "Try again"
	game_over_try_again_button.custom_minimum_size = Vector2(230.0, 54.0)
	game_over_try_again_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(game_over_try_again_button)


func show_game_over(reason := "断线结束", fade_seconds := DEFAULT_GAME_OVER_FADE_SECONDS) -> void:
	_build_game_over_overlay()
	hide_reward_choice(false)
	_hide_pause_menu_without_unpausing()
	_kill_game_over_tween()

	game_over_title_label.text = "Gameover"
	game_over_reason_label.text = reason
	game_over_overlay.visible = true
	game_over_overlay.modulate.a = 0.0
	game_over_title_label.modulate.a = 0.0
	game_over_reason_label.modulate.a = 0.0
	game_over_try_again_button.modulate.a = 0.0
	game_over_try_again_button.disabled = true
	death_countdown_panel.visible = false
	message_label.text = reason

	var fade_duration := maxf(0.01, fade_seconds)
	game_over_tween = create_pause_independent_tween()
	game_over_tween.set_parallel(true)
	game_over_tween.tween_property(game_over_overlay, "modulate:a", 1.0, fade_duration)
	game_over_tween.tween_property(
		game_over_title_label,
		"modulate:a",
		1.0,
		maxf(0.01, fade_duration * 0.32)
	).set_delay(fade_duration * 0.18)
	game_over_tween.tween_property(
		game_over_reason_label,
		"modulate:a",
		1.0,
		maxf(0.01, fade_duration * 0.28)
	).set_delay(fade_duration * 0.34)
	game_over_tween.tween_property(
		game_over_try_again_button,
		"modulate:a",
		1.0,
		maxf(0.01, fade_duration * 0.34)
	).set_delay(fade_duration * 0.56)
	game_over_tween.finished.connect(func() -> void:
		game_over_try_again_button.disabled = false
		game_over_try_again_button.grab_focus()
		game_over_tween = null
		game_over_cover_shown.emit()
	)


func fade_out_game_over_after_restart(fade_seconds := DEFAULT_GAME_OVER_FADE_SECONDS) -> void:
	_build_game_over_overlay()
	_kill_game_over_tween()
	game_over_overlay.visible = true
	game_over_overlay.modulate.a = 1.0
	game_over_try_again_button.disabled = true

	var fade_duration := maxf(0.01, fade_seconds)
	game_over_tween = create_pause_independent_tween()
	game_over_tween.tween_property(game_over_overlay, "modulate:a", 0.0, fade_duration)
	game_over_tween.finished.connect(func() -> void:
		_hide_game_over_overlay_without_signal()
		game_over_tween = null
		restart_fade_finished.emit()
	)


func reset_runtime_ui_for_restart() -> void:
	hide_reward_choice(false)
	_hide_pause_menu_without_unpausing()
	set_message("")
	death_countdown_panel.visible = false
	waiting_rebind_action = StringName()
	_refresh_rebind_buttons()


func _on_try_again_button_pressed() -> void:
	if game_over_try_again_button.disabled:
		return

	game_over_try_again_button.disabled = true
	_play_ui_sound(&"menu_next")
	try_again_requested.emit()


func _hide_game_over_overlay_without_signal() -> void:
	_kill_game_over_tween()
	if game_over_overlay == null:
		return
	game_over_overlay.visible = false
	game_over_overlay.modulate.a = 1.0
	if game_over_title_label != null:
		game_over_title_label.modulate.a = 1.0
	if game_over_reason_label != null:
		game_over_reason_label.modulate.a = 1.0
	if game_over_try_again_button != null:
		game_over_try_again_button.modulate.a = 1.0
		game_over_try_again_button.disabled = true


func _kill_game_over_tween() -> void:
	if game_over_tween != null and game_over_tween.is_valid():
		game_over_tween.kill()
	game_over_tween = null


func _is_pause_menu_event(event: InputEvent) -> bool:
	if event.is_action_pressed(ACTION_PAUSE_MENU):
		return true

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and _get_keycode_from_event(key_event) == KEY_ESCAPE:
			return true

	return false


func _ensure_pause_menu_action_defaults() -> void:
	if not InputMap.has_action(ACTION_PAUSE_MENU):
		InputMap.add_action(ACTION_PAUSE_MENU, 0.2)

	_ensure_action_key(ACTION_PAUSE_MENU, KEY_ESCAPE)
	_ensure_action_joy_button(ACTION_PAUSE_MENU, JOY_BUTTON_START)


func _ensure_action_key(action_name: StringName, physical_keycode: int) -> void:
	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventKey and _get_keycode_from_event(input_event as InputEventKey) == physical_keycode:
			return

	var key_event := InputEventKey.new()
	key_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action_name, key_event)


func _ensure_action_joy_button(action_name: StringName, button_index: int) -> void:
	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventJoypadButton and (input_event as InputEventJoypadButton).button_index == button_index:
			return

	var button_event := InputEventJoypadButton.new()
	button_event.button_index = button_index
	InputMap.action_add_event(action_name, button_event)


func _update_settings_scroll_gamepad(delta: float) -> void:
	if not is_instance_valid(settings_scroll):
		return
	if not pause_menu_overlay.visible or not settings_panel.visible:
		return
	if waiting_rebind_action != StringName():
		return

	var raw_axis := _get_strongest_joy_axis(JOY_AXIS_RIGHT_Y)
	var absolute_axis := absf(raw_axis)
	if absolute_axis <= SETTINGS_SCROLL_RIGHT_STICK_DEADZONE:
		return

	var scroll_strength := signf(raw_axis) * inverse_lerp(SETTINGS_SCROLL_RIGHT_STICK_DEADZONE, 1.0, absolute_axis)
	var scroll_delta := int(round(scroll_strength * SETTINGS_SCROLL_RIGHT_STICK_SPEED * delta))
	if scroll_delta == 0:
		scroll_delta = int(signf(scroll_strength))

	var scroll_bar := settings_scroll.get_v_scroll_bar()
	var max_scroll := int(scroll_bar.max_value)
	settings_scroll.scroll_vertical = clampi(settings_scroll.scroll_vertical + scroll_delta, 0, max_scroll)


func _get_strongest_joy_axis(axis: int) -> float:
	var strongest := 0.0
	for device_id in Input.get_connected_joypads():
		var axis_value := Input.get_joy_axis(int(device_id), axis)
		if absf(axis_value) > absf(strongest):
			strongest = axis_value
	return strongest


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
	var assignment_text := ""
	if active_input_preset == INPUT_PRESET_GAMEPAD:
		assignment_text = "    %s" % _get_gamepad_assignment_text()
	input_preset_toggle_button.text = "当前：%s    切换到：%s%s" % [current_label, next_label, assignment_text]


func _get_gamepad_assignment_text() -> String:
	var input_router := get_node_or_null("/root/InputRouter")
	if input_router == null:
		return "P1/P2 未分配"

	var player_one_name := "未分配"
	var player_two_name := "未分配"
	if input_router.has_method("get_player_device_name"):
		player_one_name = String(input_router.get_player_device_name(1))
		player_two_name = String(input_router.get_player_device_name(2))
	return "P1:%s  P2:%s" % [player_one_name, player_two_name]


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

	_notify_input_router()
	_update_input_preset_button()
	_refresh_rebind_buttons()


func _notify_input_router() -> void:
	var input_router := get_node_or_null("/root/InputRouter")
	if input_router != null and input_router.has_method("set_active_input_preset"):
		input_router.set_active_input_preset(active_input_preset)


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
	if button_index == JOY_BUTTON_START:
		return "Menu / Start / +"
	if button_index == JOY_BUTTON_BACK:
		return "View / Back / -"
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


func set_link_state(is_active: bool, seconds_left: float) -> void:
	if is_active:
		death_countdown_panel.visible = false
	else:
		var clamped_seconds: float = maxf(0.0, seconds_left)
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
