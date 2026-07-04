extends Panel

# 玩家手牌面板：
# - UI 结构放在 player_card_panel.tscn：CardStackLayer、CardTransitionLayer、CardTemplate、CardCountLabel。
# - 脚本只复制 CardTemplate、填入卡牌数据并驱动动画，避免运行时创建不可编辑的 UI 结构。

const CARD_STYLEBOXES_BY_KEY := {
	"attack_consumable": preload("res://assets/theme/player_hand_award_attack_consumable.tres"),
	"attack_unconsumable": preload("res://assets/theme/player_hand_award_attack_unconsumable.tres"),
	"other_consumable": preload("res://assets/theme/player_hand_award_enhance_consumable.tres"),
	"other_unconsumable": preload("res://assets/theme/player_hand_award_enhance_unconsumable.tres"),
}

const TAG_CONSUMABLE := "consumable"
const CARD_TYPE_ATTACK := "attack"
const CARD_TYPE_OTHER := "other"
const CARD_ACTION_PLAY := "play"
const CARD_ACTION_PASS := "pass"

@export_group("Stack Layout")
@export var max_visible_stack_cards := 10
@export var stack_x_gap := 15.0
@export var stack_y_gap := 2.4
@export var stack_rotation_step := 2.8
@export var front_card_modulate := Color.WHITE
@export var back_card_modulate := Color(0.86, 0.86, 0.86, 0.96)

@export_group("Card Animation")
@export var play_lift_offset := Vector2(0.0, -48.0)
@export var pass_lift_offset := Vector2(0.0, -24.0)
@export var play_lift_scale := Vector2(1.14, 1.14)
@export var pass_lift_scale := Vector2(1.07, 1.07)
@export var reveal_duration := 0.34
@export var top_lift_play_duration := 0.16
@export var top_lift_pass_duration := 0.13
@export var top_return_duration := 0.24
@export var top_fade_duration := 0.14

@onready var stack_layer: Control = $CardStackLayer
@onready var transition_layer: Control = $CardTransitionLayer
@onready var card_template: Panel = $CardTemplate
@onready var card_count_label: Label = $CardCountLabel
@onready var empty_label: Label = $EmptyLabel

var stack_transition_tween: Tween
var restore_hint_tween: Tween
var restore_hint_active := false
var base_scale := Vector2.ONE
var base_modulate := Color.WHITE
var stack_transition_active := false
var pending_deck_cards: Array = []
var pending_current_card: Dictionary = {}
var pending_card_count := 0
var pending_cooldown_remaining := 0.0
var pending_player_id := 0
var displayed_deck_cards: Array = []
var displayed_current_card: Dictionary = {}
var displayed_card_count := 0
var displayed_cooldown_remaining := 0.0
var displayed_player_id := 0


func _ready() -> void:
	base_scale = scale
	base_modulate = modulate
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_template.visible = false
	card_template.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var top_card := _resolve_top_card(safe_cards, current_card)
	var visible_count: int = maxi(card_count, safe_cards.size())

	if stack_transition_active:
		_store_pending_stack_state(safe_cards, top_card, visible_count, cooldown_remaining, player_id)
		return

	_apply_stack_state(safe_cards, top_card, visible_count, cooldown_remaining, player_id)


func animate_card_action(action_name: String, before_cards: Array, after_cards: Array, current_card: Dictionary, card_count: int, cooldown_remaining: float, player_id := 0, top_returns_to_bottom := false) -> void:
	var safe_before := _duplicate_card_list(before_cards)
	var safe_after := _duplicate_card_list(after_cards)
	var final_top := _resolve_top_card(safe_after, current_card)
	var final_count: int = maxi(card_count, safe_after.size())
	if safe_before.is_empty():
		load_card_stack_data(safe_after, final_top, final_count, cooldown_remaining, player_id)
		return

	_stop_stack_transition(false)
	stack_transition_active = true
	_store_pending_stack_state(safe_after, final_top, final_count, cooldown_remaining, player_id)
	_apply_stack_state(safe_before, safe_before[0], safe_before.size(), 0.0, player_id)
	_play_stack_transition(action_name, safe_before, safe_after, player_id, top_returns_to_bottom)


func set_restore_hint_active(active: bool) -> void:
	if restore_hint_active == active:
		return

	restore_hint_active = active
	if restore_hint_active:
		_play_restore_hint_loop()
	else:
		_stop_restore_hint_loop()


func _apply_stack_state(deck_cards: Array, current_card: Dictionary, card_count: int, cooldown_remaining: float, player_id := 0) -> void:
	displayed_deck_cards = _duplicate_card_list(deck_cards)
	displayed_current_card = current_card.duplicate(true)
	displayed_card_count = card_count
	displayed_cooldown_remaining = cooldown_remaining
	displayed_player_id = player_id

	card_count_label.visible = displayed_card_count > 0
	card_count_label.text = "x%d" % displayed_card_count
	empty_label.visible = displayed_card_count <= 0

	_render_card_stack(displayed_deck_cards, player_id)
	_update_top_card_text(cooldown_remaining)


func _render_card_stack(deck_cards: Array, player_id := 0) -> void:
	_clear_node_children(stack_layer)

	var display_count: int = mini(deck_cards.size(), max_visible_stack_cards)
	for draw_index in range(display_count - 1, -1, -1):
		var card_data: Dictionary = deck_cards[draw_index]
		var card_panel := _create_card_panel(card_data, draw_index, player_id, display_count, draw_index == 0)
		stack_layer.add_child(card_panel)


func _create_card_panel(card_data: Dictionary, card_index: int, player_id := 0, display_count := 1, show_text := false) -> Panel:
	var card_panel := card_template.duplicate() as Panel
	card_panel.name = "Card_%02d" % card_index
	card_panel.visible = true
	card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_panel.clip_contents = false
	card_panel.position = _get_card_position(card_index, player_id)
	card_panel.rotation_degrees = _get_card_rotation(card_index, player_id)
	card_panel.scale = _get_card_base_scale()
	card_panel.modulate = front_card_modulate if card_index == 0 else back_card_modulate
	card_panel.z_index = display_count - card_index
	card_panel.add_theme_stylebox_override("panel", _get_card_stylebox(card_data))
	_set_card_text(card_panel, card_data, show_text)
	return card_panel


func _play_stack_transition(action_name: String, before_cards: Array, after_cards: Array, player_id: int, top_returns_to_bottom: bool) -> void:
	_clear_transition_layer()

	var before_top: Dictionary = before_cards[0]
	var before_display_count: int = mini(before_cards.size(), max_visible_stack_cards)
	var after_display_count: int = mini(after_cards.size(), max_visible_stack_cards)
	var top_node := stack_layer.get_node_or_null("Card_00") as Panel
	if top_node != null:
		top_node.visible = false

	var used_after_indices := {}
	var top_target_index := -1
	if top_returns_to_bottom and not after_cards.is_empty():
		top_target_index = mini(after_cards.size() - 1, max_visible_stack_cards - 1)
		used_after_indices[top_target_index] = true

	var animated_top := _create_card_panel(before_top, 0, player_id, max_visible_stack_cards, true)
	animated_top.name = "AnimatedTopCard"
	animated_top.z_index = 220
	animated_top.modulate = front_card_modulate
	transition_layer.add_child(animated_top)

	stack_transition_tween = create_tween()
	stack_transition_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	var has_parallel_group := false
	for before_index in range(1, before_display_count):
		var card_node := stack_layer.get_node_or_null("Card_%02d" % before_index) as Panel
		if card_node == null:
			continue
		var after_index := _find_matching_after_index(before_cards[before_index], after_cards, used_after_indices)
		if after_index >= 0 and after_index < max_visible_stack_cards:
			used_after_indices[after_index] = true
			_set_card_text_visible(card_node, after_index == 0)
			_add_parallel_property(stack_transition_tween, has_parallel_group, card_node, "position", _get_card_position(after_index, player_id), reveal_duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			has_parallel_group = true
			_add_parallel_property(stack_transition_tween, has_parallel_group, card_node, "rotation_degrees", _get_card_rotation(after_index, player_id), reveal_duration, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			_add_parallel_property(stack_transition_tween, has_parallel_group, card_node, "modulate", front_card_modulate if after_index == 0 else back_card_modulate, reveal_duration * 0.82, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
			card_node.z_index = after_display_count - after_index
		else:
			_add_parallel_property(stack_transition_tween, has_parallel_group, card_node, "modulate:a", 0.0, 0.18, Tween.TRANS_SINE, Tween.EASE_IN)
			has_parallel_group = true

	var top_start_position := _get_card_position(0, player_id)
	var lift_offset := play_lift_offset if action_name == CARD_ACTION_PLAY else pass_lift_offset
	var lift_scale := play_lift_scale if action_name == CARD_ACTION_PLAY else pass_lift_scale
	var lift_position := top_start_position + lift_offset
	var lift_duration := top_lift_play_duration if action_name == CARD_ACTION_PLAY else top_lift_pass_duration
	var target_lift_scale := _get_card_base_scale() * lift_scale

	_add_parallel_property(stack_transition_tween, has_parallel_group, animated_top, "position", lift_position, lift_duration, Tween.TRANS_BACK, Tween.EASE_OUT)
	has_parallel_group = true
	_add_parallel_property(stack_transition_tween, has_parallel_group, animated_top, "scale", target_lift_scale, lift_duration, Tween.TRANS_BACK, Tween.EASE_OUT)
	_add_parallel_property(stack_transition_tween, has_parallel_group, animated_top, "rotation_degrees", _get_card_rotation(0, player_id) + _get_stack_direction(player_id) * 2.5, lift_duration, Tween.TRANS_SINE, Tween.EASE_OUT)

	stack_transition_tween.tween_interval(0.02)
	if top_returns_to_bottom and top_target_index >= 0:
		var target_position := _get_card_position(top_target_index, player_id)
		var target_rotation := _get_card_rotation(top_target_index, player_id)
		var move_duration := top_return_duration if action_name == CARD_ACTION_PASS else top_return_duration * 0.85
		stack_transition_tween.tween_property(animated_top, "position", target_position, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		stack_transition_tween.parallel().tween_property(animated_top, "rotation_degrees", target_rotation, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		stack_transition_tween.parallel().tween_property(animated_top, "scale", _get_card_base_scale(), move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		stack_transition_tween.parallel().tween_property(animated_top, "modulate", back_card_modulate, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_set_card_text_visible(animated_top, false)
	else:
		stack_transition_tween.tween_property(animated_top, "position", lift_position + Vector2(0.0, -24.0), top_fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		stack_transition_tween.parallel().tween_property(animated_top, "scale", target_lift_scale * 1.05, top_fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		stack_transition_tween.parallel().tween_property(animated_top, "modulate:a", 0.0, top_fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	stack_transition_tween.finished.connect(_finish_stack_transition)


func _finish_stack_transition() -> void:
	stack_transition_active = false
	_clear_transition_layer()
	_apply_stack_state(pending_deck_cards, pending_current_card, pending_card_count, pending_cooldown_remaining, pending_player_id)


func _stop_stack_transition(apply_pending := true) -> void:
	if stack_transition_tween != null and stack_transition_tween.is_valid():
		stack_transition_tween.kill()
	stack_transition_tween = null
	if not stack_transition_active:
		_clear_transition_layer()
		return
	stack_transition_active = false
	_clear_transition_layer()
	if apply_pending:
		_apply_stack_state(pending_deck_cards, pending_current_card, pending_card_count, pending_cooldown_remaining, pending_player_id)


func _clear_transition_layer() -> void:
	_clear_node_children(transition_layer)


func _clear_node_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _set_card_text(card_panel: Panel, card_data: Dictionary, visible: bool) -> void:
	var title_label := card_panel.get_node_or_null("CardTextBox/CardTitle") as Label
	var description_label := card_panel.get_node_or_null("CardTextBox/CardDescrip") as Label
	if title_label != null:
		title_label.text = str(card_data.get("name", "未命名牌"))
	if description_label != null:
		description_label.text = str(card_data.get("description", ""))
	_set_card_text_visible(card_panel, visible)


func _set_card_text_visible(card_panel: Panel, visible: bool) -> void:
	var text_box := card_panel.get_node_or_null("CardTextBox") as Control
	if text_box != null:
		text_box.visible = visible


func _update_top_card_text(cooldown_remaining: float) -> void:
	if displayed_deck_cards.is_empty():
		return

	var top_node := stack_layer.get_node_or_null("Card_00") as Panel
	var title_label: Label = null
	if top_node != null:
		title_label = top_node.get_node_or_null("CardTextBox/CardTitle") as Label
	if title_label == null:
		return

	var top_card: Dictionary = displayed_current_card
	if top_card.is_empty():
		top_card = displayed_deck_cards[0]
	var cooldown_text := ""
	if cooldown_remaining > 0.0:
		cooldown_text = " %.1fs" % cooldown_remaining
	title_label.text = "%s%s" % [str(top_card.get("name", "未命名牌")), cooldown_text]


func _add_parallel_property(tween: Tween, has_parallel_group: bool, target: Object, property: String, final_value, duration: float, transition_type: int, ease_type: int) -> void:
	var tweener
	if has_parallel_group:
		tweener = tween.parallel().tween_property(target, property, final_value, duration)
	else:
		tweener = tween.tween_property(target, property, final_value, duration)
	tweener.set_trans(transition_type).set_ease(ease_type)


func _get_card_position(card_index: int, player_id := 0) -> Vector2:
	var direction := _get_stack_direction(player_id)
	return _get_front_card_position(player_id) + Vector2(
		direction * card_index * stack_x_gap,
		card_index * stack_y_gap
	)


func _get_card_rotation(card_index: int, player_id := 0) -> float:
	return card_template.rotation_degrees + _get_stack_direction(player_id) * card_index * stack_rotation_step


func _get_front_card_position(player_id := 0) -> Vector2:
	var template_position := card_template.position
	if _get_stack_direction(player_id) < 0.0:
		var card_size := _get_card_size()
		return Vector2(maxf(0.0, size.x - template_position.x - card_size.x), template_position.y)
	return template_position


func _get_card_size() -> Vector2:
	if card_template.size.x <= 0.0 or card_template.size.y <= 0.0:
		return Vector2(160.0, 280.0)
	return card_template.size


func _get_card_base_scale() -> Vector2:
	return card_template.scale


func _get_stack_direction(player_id := 0) -> float:
	return -1.0 if player_id == 2 else 1.0


func _get_card_stylebox(card_data: Dictionary) -> StyleBox:
	var card_type := str(card_data.get("type", CARD_TYPE_OTHER))
	var type_key := "attack" if card_type == CARD_TYPE_ATTACK else "other"
	var consume_key := "consumable" if _card_has_tag(card_data, TAG_CONSUMABLE) else "unconsumable"
	var key := "%s_%s" % [type_key, consume_key]
	return CARD_STYLEBOXES_BY_KEY.get(key, CARD_STYLEBOXES_BY_KEY["other_unconsumable"])


func _resolve_top_card(deck_cards: Array, current_card: Dictionary) -> Dictionary:
	if not current_card.is_empty():
		return current_card.duplicate(true)
	if not deck_cards.is_empty() and deck_cards[0] is Dictionary:
		return (deck_cards[0] as Dictionary).duplicate(true)
	return {}


func _store_pending_stack_state(deck_cards: Array, current_card: Dictionary, card_count: int, cooldown_remaining: float, player_id := 0) -> void:
	pending_deck_cards = _duplicate_card_list(deck_cards)
	pending_current_card = current_card.duplicate(true)
	pending_card_count = card_count
	pending_cooldown_remaining = cooldown_remaining
	pending_player_id = player_id


func _duplicate_card_list(deck_cards: Array) -> Array:
	var duplicated := []
	for card_data in deck_cards:
		if card_data is Dictionary:
			duplicated.append((card_data as Dictionary).duplicate(true))
	return duplicated


func _find_matching_after_index(card_data: Dictionary, after_cards: Array, used_after_indices: Dictionary) -> int:
	for index in range(mini(after_cards.size(), max_visible_stack_cards)):
		if used_after_indices.has(index):
			continue
		if after_cards[index] is Dictionary and _cards_match(card_data, after_cards[index]):
			return index
	return -1


func _cards_match(left_card: Dictionary, right_card: Dictionary) -> bool:
	return str(left_card.get("id", "")) == str(right_card.get("id", "")) \
		and str(left_card.get("effect_id", "")) == str(right_card.get("effect_id", "")) \
		and str(left_card.get("name", "")) == str(right_card.get("name", ""))


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
