extends Panel

# 脚本说明：
# - PLAYER_CARD_STYLEBOXES_BY_KEY：8 种玩家手牌主题，按玩家、攻击/增益、可消耗/不可消耗切换。
# - card_descrip/card_title/card_count_label：面板内文本节点，分别显示描述、标题和当前牌堆张数。
# - load_card_and_theme(res)：兼容编辑器/资源直接预览入口，把 CardDefinition 转成运行时字典后显示。
# - load_card_data(card_data, card_count, cooldown_remaining, player_id)：HUD 运行时入口，显示当前牌、牌数和冷却。
# - set_restore_hint_active(active)：断线期间当前牌是恢复牌时开启循环提示动画。
# - restore_hint_tween：恢复牌提示动画 Tween，循环高亮/变暗/放大/缩小。
# - base_scale/base_modulate：面板原始视觉状态，关闭提示动画时恢复。
# - _apply_card_theme(card_data)：根据运行时字典里的 type/tags 选择卡面。
# - _get_card_face_key(card_data, player_id)：把玩家编号、类型和消耗词条组合成卡面 key。
# - _card_has_tag(card_data, tag)：兼容 Array 和 PackedStringArray 的词条判断。
# - _play_restore_hint_loop()：启动恢复牌循环提示动画。
# - _stop_restore_hint_loop()：停止提示动画并恢复视觉状态。

const PLAYER_CARD_STYLEBOXES_BY_KEY := {
	"p1_attack_consumable": preload("res://assets/theme/player_card_attack_consumable_p1.tres"),
	"p1_attack_unconsumable": preload("res://assets/theme/player_card_attack_unconsumable_p1.tres"),
	"p1_other_consumable": preload("res://assets/theme/player_card_enhance_consumable_p1.tres"),
	"p1_other_unconsumable": preload("res://assets/theme/player_card_enhance_unconsumable_p1.tres"),
	"p2_attack_consumable": preload("res://assets/theme/player_card_attack_consumable_p2.tres"),
	"p2_attack_unconsumable": preload("res://assets/theme/player_card_attack_unconsumable_p2.tres"),
	"p2_other_consumable": preload("res://assets/theme/player_card_enhance_consumable_p2.tres"),
	"p2_other_unconsumable": preload("res://assets/theme/player_card_enhance_unconsumable_p2.tres"),
}
const TAG_CONSUMABLE := "consumable"
const CARD_TYPE_ATTACK := "attack"
const CARD_TYPE_OTHER := "other"

@onready var card_descrip: Label = $VBoxContainer/CardDescrip
@onready var card_title: Label = $VBoxContainer/CardTitle
@onready var card_count_label: Label = $Label

var restore_hint_tween: Tween
var restore_hint_active := false
var base_scale := Vector2.ONE
var base_modulate := Color.WHITE


func _ready() -> void:
	base_scale = scale
	base_modulate = modulate
	pivot_offset = size * 0.5


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5


func load_card_and_theme(res: CardDefinition) -> void:
	if res == null:
		load_card_data({}, 0, 0.0)
		return

	load_card_data(res.to_card_data(), 0, 0.0)


func load_card_data(card_data: Dictionary, card_count: int, cooldown_remaining: float, player_id := 0) -> void:
	card_count_label.text = str(maxi(0, card_count))
	if card_data.is_empty():
		card_title.text = "无牌"
		card_descrip.text = ""
		_apply_card_theme({
			"type": CARD_TYPE_OTHER,
			"tags": [],
		}, player_id)
		return

	_apply_card_theme(card_data, player_id)
	var cooldown_text := ""
	if cooldown_remaining > 0.0:
		cooldown_text = "  %.1fs" % cooldown_remaining
	card_title.text = "%s%s" % [str(card_data.get("name", "未命名牌")), cooldown_text]
	card_descrip.text = str(card_data.get("description", ""))


func set_restore_hint_active(active: bool) -> void:
	if restore_hint_active == active:
		return

	restore_hint_active = active
	if restore_hint_active:
		_play_restore_hint_loop()
	else:
		_stop_restore_hint_loop()


func _apply_card_theme(card_data: Dictionary, player_id := 0) -> void:
	var face_key := _get_card_face_key(card_data, player_id)
	add_theme_stylebox_override("panel", PLAYER_CARD_STYLEBOXES_BY_KEY.get(face_key, PLAYER_CARD_STYLEBOXES_BY_KEY["p1_other_unconsumable"]))


func _get_card_face_key(card_data: Dictionary, player_id := 0) -> String:
	var resolved_player_id := player_id
	if resolved_player_id <= 0:
		resolved_player_id = int(card_data.get("owner_player_id", 1))
	resolved_player_id = 2 if resolved_player_id == 2 else 1

	var card_type := str(card_data.get("type", CARD_TYPE_OTHER))
	var type_key := "attack" if card_type == CARD_TYPE_ATTACK else "other"
	var consume_key := "consumable" if _card_has_tag(card_data, TAG_CONSUMABLE) else "unconsumable"
	return "p%d_%s_%s" % [resolved_player_id, type_key, consume_key]


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
