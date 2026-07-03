extends CanvasLayer
class_name GameHUD

# 脚本说明：
# - health_label：显示肉体血量文字的 Label。文档要求血量放在醒目位置，因此它位于 HUD 顶部。
# - health_bar：显示肉体血量比例的 ProgressBar。它和 health_label 一起强化受击反馈。
# - link_status_label：显示连线稳定、断线倒计时、胜利或失败状态的 Label。
# - player_one_card_label：玩家 1 当前牌显示。它只读牌堆顶，不改变牌堆。
# - player_two_card_label：玩家 2 当前牌显示。它只读牌堆顶，不改变牌堆。
# - player_one_count_label：玩家 1 当前战斗牌堆剩余数量。
# - player_two_count_label：玩家 2 当前战斗牌堆剩余数量。
# - message_label：显示最近一次卡牌、任务点或结束状态消息。
# - reward_choice_overlay：任务点奖励三选一界面根节点。默认隐藏，玩家到达专属任务点后显示。
# - reward_title_label：奖励界面标题，显示是哪个玩家正在选择奖励。
# - reward_hint_label：奖励界面提示，说明只能选择一张牌加入该玩家牌堆。
# - reward_choice_buttons：三个奖励按钮的数组。每个按钮对应一张候选牌，按钮文本由卡牌名称、类型和说明组成。
# - sub_viewport：UI 内承载主世界画面的 SubViewport。它共享主场景 World2D，但必须使用自己的 Camera2D。
# - sub_viewport_camera：SubViewport 专属的镜像相机。它不参与主场景逻辑，只复制主 Camera2D 的视角。
# - source_world_camera：主场景真正用于跟随和边界计算的 Camera2D。
# - active_reward_player_id：当前正在选择奖励的玩家编号。选择按钮发信号时会把这个编号传给主控制器。
# - active_reward_cards：当前显示的 3 张候选牌数据。选择按钮按索引从这里取出被选择的牌。
# - card_reward_selected(player_id, card_data)：玩家点选某张奖励牌时发出，主控制器收到后把牌加入对应玩家牌堆。
# - _ready()：缓存 tscn 中已经布好的 UI 节点，并设置初始提示为空。
# - _process(delta)：每帧同步 SubViewport 的镜像相机，避免 UI 视口和主相机脱节。
# - initialize(world_camera)：接收主相机，把主场景 World2D 交给 SubViewport，并立即同步一次视角。
# - _sync_subviewport_camera()：复制主相机的位置、缩放和边界到 SubViewport 专属相机。
# - set_health(current_health, max_health)：更新醒目的血量条和血量文字。
# - set_link_state(is_active, seconds_left)：更新连线稳定或断线倒计时文字。
# - set_player_deck_status(player_id, card_name, card_count, cooldown_remaining)：更新指定玩家的当前牌、牌数和冷却状态。
# - set_message(message)：更新短消息区域，用于反馈任务点拾取和打牌结果。
# - set_game_result(message)：显示最终结果，并把结果同步到连线状态区域。
# - show_reward_choice(player_id, reward_cards)：显示任务点奖励面板，把 3 张候选牌渲染到按钮上。
# - hide_reward_choice()：隐藏任务点奖励面板并清空当前候选牌。
# - _on_reward_button_pressed(index)：处理玩家点击第 index 个奖励按钮，发出 card_reward_selected 信号。
# - _format_reward_button_text(index, card_data)：把卡牌字典格式化成按钮上可读的三行文本。

signal card_reward_selected(player_id: int, card_data: Dictionary)

@onready var sub_viewport: SubViewport = $Root/SubViewportContainer/SubViewport
@onready var sub_viewport_camera: Camera2D = $Root/SubViewportContainer/SubViewport/ViewportCamera2D
@onready var health_label: Label = $Root/TopStrip/HealthLabel
@onready var health_bar: ProgressBar = $Root/TopStrip/HealthBar
@onready var link_status_label: Label = $Root/TopStrip/LinkStatusLabel
@onready var player_one_card_label: Label = $Root/PlayerOnePanel/CardLabel
@onready var player_two_card_label: Label = $Root/PlayerTwoPanel/CardLabel
@onready var player_one_count_label: Label = $Root/PlayerOnePanel/CountLabel
@onready var player_two_count_label: Label = $Root/PlayerTwoPanel/CountLabel
@onready var message_label: Label = $Root/MessageLabel
@onready var reward_choice_overlay: Control = $Root/RewardChoiceOverlay
@onready var reward_title_label: Label = $Root/RewardChoiceOverlay/Panel/TitleLabel
@onready var reward_hint_label: Label = $Root/RewardChoiceOverlay/Panel/HintLabel
@onready var reward_choice_buttons: Array[Button] = [
	$Root/RewardChoiceOverlay/Panel/ChoiceOneButton,
	$Root/RewardChoiceOverlay/Panel/ChoiceTwoButton,
	$Root/RewardChoiceOverlay/Panel/ChoiceThreeButton,
]

var active_reward_player_id := 0
var active_reward_cards: Array = []
var source_world_camera: Camera2D


func _ready() -> void:
	set_message("")
	hide_reward_choice()
	for index in reward_choice_buttons.size():
		reward_choice_buttons[index].pressed.connect(_on_reward_button_pressed.bind(index))


func _process(_delta: float) -> void:
	_sync_subviewport_camera()


func initialize(world_camera: Camera2D) -> void:
	source_world_camera = world_camera
	sub_viewport.world_2d = source_world_camera.get_viewport().world_2d
	sub_viewport_camera.make_current()
	_sync_subviewport_camera()


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


func set_health(current_health: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "HP %d / %d" % [roundi(current_health), roundi(max_health)]


func set_link_state(is_active: bool, seconds_left: float) -> void:
	if is_active:
		link_status_label.text = "连线稳定"
	else:
		link_status_label.text = "断线 %.1fs" % seconds_left


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


func hide_reward_choice() -> void:
	reward_choice_overlay.visible = false
	active_reward_player_id = 0
	active_reward_cards.clear()


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
