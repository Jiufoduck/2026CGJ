extends Panel

# 脚本说明：
# - ATTACK/ATTACK_UNCONSU/ENHANCE/ENHANCE_UNCONSU：四种卡面底图，按卡牌类型和是否消耗切换。
# - card_descrip/card_title/card_count_label：面板内文本节点，分别显示描述、标题和当前牌堆张数。
# - load_card_and_theme(res)：兼容编辑器/资源直接预览入口，把 CardDefinition 转成运行时字典后显示。
# - load_card_data(card_data, card_count, cooldown_remaining)：HUD 运行时入口，显示当前牌、牌数和冷却。
# - set_restore_hint_active(active)：断线期间当前牌是恢复牌时开启循环提示动画。
# - restore_hint_tween：恢复牌提示动画 Tween，循环高亮/变暗/放大/缩小。
# - base_scale/base_modulate：面板原始视觉状态，关闭提示动画时恢复。
# - _apply_card_theme(card_data)：根据运行时字典里的 type/tags 选择卡面。
# - _card_has_tag(card_data, tag)：兼容 Array 和 PackedStringArray 的词条判断。
# - _play_restore_hint_loop()：启动恢复牌循环提示动画。
# - _stop_restore_hint_loop()：停止提示动画并恢复视觉状态。

const ATTACK = preload("uid://c7ole2s1378hw")
const ATTACK_UNCONSU = preload("uid://s1u4hagxjvle")
const ENHANCE = preload("uid://cwfyatongmryw")
const ENHANCE_UNCONSU = preload("uid://cww82mdc165ql")
const TAG_CONSUMABLE := "consumable"
const CARD_TYPE_ATTACK := "attack"
const CARD_TYPE_OTHER := "other"

@onready var card_descrip: Label = $VBoxContainer/CardDescrip
@onready var card_title: Label = $VBoxContainer/CardTitle
@onready var card_count_label: Label = $Panel/Label

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


func load_card_data(card_data: Dictionary, card_count: int, cooldown_remaining: float) -> void:
	card_count_label.text = str(maxi(0, card_count))
	if card_data.is_empty():
		card_title.text = "无牌"
		card_descrip.text = ""
		_apply_card_theme({
			"type": CARD_TYPE_OTHER,
			"tags": [],
		})
		return

	_apply_card_theme(card_data)
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


func _apply_card_theme(card_data: Dictionary) -> void:
	var card_type := str(card_data.get("type", CARD_TYPE_OTHER))
	if _card_has_tag(card_data, TAG_CONSUMABLE):
		if card_type == CARD_TYPE_ATTACK:
			add_theme_stylebox_override("panel", ATTACK)
		else:
			add_theme_stylebox_override("panel", ENHANCE)
	else:
		if card_type == CARD_TYPE_ATTACK:
			add_theme_stylebox_override("panel", ATTACK_UNCONSU)
		else:
			add_theme_stylebox_override("panel", ENHANCE_UNCONSU)


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
