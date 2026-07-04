extends Panel

# 玩家手牌面板：
# - 根 Panel 只负责承载，不再直接显示某一张卡面。
# - CardStackLayer 运行时绘制玩家当前整副牌堆，顶牌在最前。
# - 文字与数量单独置于高 z_index，避免卡面遮挡标题/描述。

const CARD_STYLEBOXES_BY_KEY := {
	"attack_consumable": preload("res://assets/theme/player_hand_award_attack_consumable.tres"),
	"attack_unconsumable": preload("res://assets/theme/player_hand_award_attack_unconsumable.tres"),
	"other_consumable": preload("res://assets/theme/player_hand_award_enhance_consumable.tres"),
	"other_unconsumable": preload("res://assets/theme/player_hand_award_enhance_unconsumable.tres"),
}

const TAG_CONSUMABLE := "consumable"
const CARD_TYPE_ATTACK := "attack"
const CARD_TYPE_OTHER := "other"
const CARD_SIZE := Vector2(108.0, 180.0)
const PANEL_SIZE := Vector2(300.0, 214.0)
const MAX_VISIBLE_STACK_CARDS := 10
const STACK_X_GAP := 15.0
const STACK_Y_GAP := 2.4
const STACK_ROTATION_STEP := 2.8
const TITLE_FONT_SIZE := 12
const DESCRIPTION_FONT_SIZE := 7
const COUNT_FONT_SIZE := 18

@onready var card_descrip: Label = $VBoxContainer/CardDescrip
@onready var card_title: Label = $VBoxContainer/CardTitle
@onready var text_box: VBoxContainer = $VBoxContainer
@onready var card_count_label: Label = $Label

var stack_layer: Control
var restore_hint_tween: Tween
var restore_hint_active := false
var base_scale := Vector2.ONE
var base_modulate := Color.WHITE


func _ready() -> void:
	base_scale = scale
	base_modulate = modulate
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_ensure_stack_layer()
	_configure_text_nodes()
	pivot_offset = size * 0.5


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5


func load_card_and_theme(res: CardDefinition) -> void:
	if res == null:
		load_card_stack_data([], {}, 0, 0.0, 0)
		return

	var card_data := res.to_card_data()
	load_card_stack_data([card_data], card_data, 1, 0.0, int(card_data.get("owner_player_id", 0)))


func load_card_data(card_data: Dictionary, card_count: int, cooldown_remaining: float, player_id := 0) -> void:
	var deck_cards := []
	if not card_data.is_empty():
		deck_cards.append(card_data.duplicate(true))
	load_card_stack_data(deck_cards, card_data, card_count, cooldown_remaining, player_id)


func load_card_stack_data(deck_cards: Array, current_card: Dictionary, card_count: int, cooldown_remaining: float, player_id := 0) -> void:
	var safe_cards := _duplicate_card_list(deck_cards)
	if safe_cards.is_empty() and not current_card.is_empty():
		safe_cards.append(current_card.duplicate(true))

	var top_card := current_card
	if top_card.is_empty() and not safe_cards.is_empty():
		top_card = safe_cards[0]

	var visible_count: int = maxi(card_count, safe_cards.size())
	card_count_label.visible = visible_count > 0
	card_count_label.text = "x%d" % visible_count

	_render_card_stack(safe_cards, player_id)
	_layout_text_nodes(player_id)

	if top_card.is_empty():
		card_title.text = "无牌"
		card_descrip.text = ""
		return

	var cooldown_text := ""
	if cooldown_remaining > 0.0:
		cooldown_text = " %.1fs" % cooldown_remaining
	card_title.text = "%s%s" % [str(top_card.get("name", "未命名牌")), cooldown_text]
	card_descrip.text = str(top_card.get("description", ""))


func set_restore_hint_active(active: bool) -> void:
	if restore_hint_active == active:
		return

	restore_hint_active = active
	if restore_hint_active:
		_play_restore_hint_loop()
	else:
		_stop_restore_hint_loop()


func _ensure_stack_layer() -> void:
	if stack_layer != null:
		return

	stack_layer = Control.new()
	stack_layer.name = "CardStackLayer"
	stack_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack_layer.clip_contents = false
	stack_layer.z_index = 0
	stack_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack_layer.offset_left = 0.0
	stack_layer.offset_top = 0.0
	stack_layer.offset_right = 0.0
	stack_layer.offset_bottom = 0.0
	add_child(stack_layer)
	move_child(stack_layer, 0)


func _configure_text_nodes() -> void:
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.z_index = 100
	text_box.add_theme_constant_override("separation", 1)

	card_title.label_settings = null
	card_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_title.z_index = 101
	card_title.clip_text = true
	card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card_title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	card_title.add_theme_color_override("font_color", Color(0.20, 0.16, 0.13, 1.0))

	card_descrip.label_settings = null
	card_descrip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_descrip.z_index = 101
	card_descrip.clip_text = true
	card_descrip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_descrip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_descrip.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card_descrip.add_theme_font_size_override("font_size", DESCRIPTION_FONT_SIZE)
	card_descrip.add_theme_color_override("font_color", Color(0.25, 0.20, 0.16, 1.0))

	card_count_label.label_settings = null
	card_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_count_label.z_index = 100
	card_count_label.add_theme_font_size_override("font_size", COUNT_FONT_SIZE)
	card_count_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.78, 1.0))
	card_count_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	card_count_label.add_theme_constant_override("shadow_offset_x", 2)
	card_count_label.add_theme_constant_override("shadow_offset_y", 2)
	move_child(text_box, get_child_count() - 1)
	move_child(card_count_label, get_child_count() - 1)


func _render_card_stack(deck_cards: Array, player_id := 0) -> void:
	for child in stack_layer.get_children():
		stack_layer.remove_child(child)
		child.queue_free()

	var display_count: int = mini(deck_cards.size(), MAX_VISIBLE_STACK_CARDS)
	for draw_index in range(display_count - 1, -1, -1):
		var card_data: Dictionary = deck_cards[draw_index]
		var card_panel := Panel.new()
		card_panel.name = "Card_%02d" % draw_index
		card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_panel.clip_contents = false
		card_panel.size = CARD_SIZE
		card_panel.custom_minimum_size = CARD_SIZE
		card_panel.pivot_offset = CARD_SIZE * 0.5
		card_panel.position = _get_card_position(draw_index, player_id)
		card_panel.rotation_degrees = _get_card_rotation(draw_index, player_id)
		card_panel.modulate = Color.WHITE if draw_index == 0 else Color(0.86, 0.86, 0.86, 0.96)
		card_panel.z_index = display_count - draw_index
		card_panel.add_theme_stylebox_override("panel", _get_card_stylebox(card_data))
		stack_layer.add_child(card_panel)

	move_child(stack_layer, 0)


func _layout_text_nodes(player_id := 0) -> void:
	var front_x := _get_front_card_x(player_id)
	text_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	text_box.position = Vector2(front_x + 11.0, 101.0)
	text_box.size = Vector2(CARD_SIZE.x - 22.0, 60.0)
	card_title.custom_minimum_size = Vector2(CARD_SIZE.x - 22.0, 17.0)
	card_descrip.custom_minimum_size = Vector2(CARD_SIZE.x - 22.0, 40.0)

	card_count_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	card_count_label.position = Vector2(front_x, CARD_SIZE.y + 2.0)
	card_count_label.size = Vector2(CARD_SIZE.x, 24.0)
	card_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	move_child(text_box, get_child_count() - 1)
	move_child(card_count_label, get_child_count() - 1)


func _get_card_position(card_index: int, player_id := 0) -> Vector2:
	var direction := _get_stack_direction(player_id)
	return Vector2(
		_get_front_card_x(player_id) + direction * card_index * STACK_X_GAP,
		card_index * STACK_Y_GAP
	)


func _get_card_rotation(card_index: int, player_id := 0) -> float:
	return _get_stack_direction(player_id) * card_index * STACK_ROTATION_STEP


func _get_front_card_x(player_id := 0) -> float:
	if _get_stack_direction(player_id) < 0.0:
		return maxf(0.0, PANEL_SIZE.x - CARD_SIZE.x)
	return 0.0


func _get_stack_direction(player_id := 0) -> float:
	return -1.0 if player_id == 2 else 1.0


func _get_card_stylebox(card_data: Dictionary) -> StyleBox:
	var card_type := str(card_data.get("type", CARD_TYPE_OTHER))
	var type_key := "attack" if card_type == CARD_TYPE_ATTACK else "other"
	var consume_key := "consumable" if _card_has_tag(card_data, TAG_CONSUMABLE) else "unconsumable"
	var key := "%s_%s" % [type_key, consume_key]
	return CARD_STYLEBOXES_BY_KEY.get(key, CARD_STYLEBOXES_BY_KEY["other_unconsumable"])


func _duplicate_card_list(deck_cards: Array) -> Array:
	var duplicated := []
	for card_data in deck_cards:
		if card_data is Dictionary:
			duplicated.append((card_data as Dictionary).duplicate(true))
	return duplicated


func _card_has_tag(card_data: Dictionary, tag: String) -> bool:
	for tag_value in card_data.get("tags", []):
		if str(tag_value) == tag:
			return true
	return false


func _play_restore_hint_loop() -> void:
	_stop_restore_hint_loop(false)
	pivot_offset = size * 0.5
	restore_hint_tween = create_tween()
	restore_hint_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	restore_hint_tween.set_loops()
	restore_hint_tween.tween_property(self, "scale", base_scale * 1.08, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	restore_hint_tween.parallel().tween_property(self, "modulate", Color(1.0, 0.96, 0.72, 1.0), 0.42)
	restore_hint_tween.tween_property(self, "scale", base_scale * 0.96, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	restore_hint_tween.parallel().tween_property(self, "modulate", Color(0.56, 0.56, 0.56, 1.0), 0.42)


func _stop_restore_hint_loop(restore_visual := true) -> void:
	if restore_hint_tween != null and restore_hint_tween.is_valid():
		restore_hint_tween.kill()
	restore_hint_tween = null
	if restore_visual:
		scale = base_scale
		modulate = base_modulate
