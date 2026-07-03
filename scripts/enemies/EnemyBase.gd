extends CharacterBody2D
class_name EnemyBase

# 脚本说明：
# - enemy_type_id：敌人类型编号。不同敌人场景可以通过它区分视觉和后续行为。
# - move_speed：敌人基础移动速度。卡牌冻结时不会清空它，只是临时停止移动。
# - move_direction：敌人当前移动方向。子类 AI 可以每帧改它，再交给基类移动。
# - max_health：敌人最大血量。当前血量降到 0 后敌人隐藏并停止碰撞。
# - contact_damage：敌人与肉体接触时造成的伤害。
# - contact_damage_cooldown：连续接触肉体时的伤害间隔。
# - can_move：是否允许当前敌人按 move_direction 移动。机关类敌人可以关闭它。
# - current_health：敌人当前血量。
# - contact_damage_timer：距离下一次允许接触伤害还剩多少秒。
# - card_frozen：是否被 B9 群体冻结。冻结时停止移动和攻击。
# - visual_polygon：敌人的白模视觉节点引用。节点在 tscn 中存在，不由脚本创建。
# - damage_area：敌人用于检测肉体接触的 Area2D。远程敌人可以移除它。
# - _ready()：初始化血量、分组、伤害区域和视觉样式。
# - _physics_process(delta)：执行冻结检查、简单移动、碰撞反弹和接触伤害计时。
# - take_damage(amount)：扣除敌人血量，血量归零后禁用敌人。
# - force_defeat()：卡牌直接消灭敌人的入口。
# - is_alive()：返回敌人是否仍能被卡牌影响。
# - apply_knockback(motion)：按碰撞移动敌人一段距离，用于清场和击退。
# - set_card_frozen(enabled)：切换卡牌冻结状态。
# - is_card_frozen()：返回当前是否被卡牌冻结。
# - _try_damage_body()：检查伤害区域内是否有肉体，有则按冷却扣血并传入伤害来源。
# - _refresh_visual_style()：根据敌人类型设置默认颜色。
# - _disable_enemy()：关闭敌人显示、物理和监控。

@export var enemy_type_id := 1
@export var move_speed := 90.0
@export var move_direction := Vector2.LEFT
@export var max_health := 30.0
@export var contact_damage := 10.0
@export var contact_damage_cooldown := 1.0
@export var can_move := true

var current_health := 30.0
var contact_damage_timer := 0.0
var card_frozen := false

@onready var visual_polygon: Polygon2D = $Visual
@onready var damage_area: Area2D = get_node_or_null(^"DamageArea")


func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	contact_damage_timer = 0.0
	if damage_area != null:
		damage_area.monitoring = true
	_refresh_visual_style()


func _physics_process(delta: float) -> void:
	contact_damage_timer = maxf(0.0, contact_damage_timer - delta)
	if card_frozen:
		velocity = Vector2.ZERO
		return

	if can_move and move_direction.length() > 0.0:
		velocity = move_direction.normalized() * move_speed
		move_and_slide()
		if get_slide_collision_count() > 0:
			var collision := get_slide_collision(0)
			move_direction = move_direction.bounce(collision.get_normal()).normalized()
	else:
		velocity = Vector2.ZERO

	_try_damage_body()


func take_damage(amount: float) -> void:
	if amount <= 0.0 or current_health <= 0.0:
		return

	current_health = maxf(0.0, current_health - amount)
	if current_health <= 0.0:
		_disable_enemy()


func force_defeat() -> void:
	if current_health <= 0.0:
		return
	current_health = 0.0
	_disable_enemy()


func is_alive() -> bool:
	return current_health > 0.0 and visible


func apply_knockback(motion: Vector2) -> void:
	if motion.length() <= 0.001 or not is_alive():
		return

	var collision := move_and_collide(motion)
	if collision != null:
		velocity = Vector2.ZERO


func set_card_frozen(enabled: bool) -> void:
	card_frozen = enabled
	if card_frozen:
		velocity = Vector2.ZERO


func is_card_frozen() -> bool:
	return card_frozen


func _try_damage_body() -> void:
	if card_frozen or contact_damage_timer > 0.0 or damage_area == null:
		return

	for body in damage_area.get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(contact_damage, self)
			contact_damage_timer = contact_damage_cooldown
			return


func _refresh_visual_style() -> void:
	if visual_polygon == null:
		return

	if enemy_type_id == 1:
		visual_polygon.color = Color(0.95, 0.25, 0.25, 1.0)
	elif enemy_type_id == 2:
		visual_polygon.color = Color(0.75, 0.35, 1.0, 1.0)
	else:
		visual_polygon.color = Color(0.25, 0.95, 0.65, 1.0)


func _disable_enemy() -> void:
	hide()
	set_physics_process(false)
	set_collision_layer_value(4, false)
	set_collision_mask_value(2, false)
	remove_from_group("enemies")
	if damage_area != null:
		damage_area.monitoring = false
