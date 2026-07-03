extends CharacterBody2D
class_name EnemyBase

# 脚本说明：
# - enemy_type_id：敌人类型编号。文档要求一共三种敌人，三个 tscn 会分别设置为 1、2、3。
# - move_speed：敌人占位移动速度。AI 之后再实现时可以替换当前简单巡逻逻辑。
# - move_direction：敌人的初始移动方向。当前脚本只做白模巡逻，撞到场景矩形或障碍后反弹。
# - max_health：敌人最大血量。虽然当前文档没有要求攻击结算细节，但保留血量方便后续攻击牌接入。
# - contact_damage：敌人与肉体接触时造成的伤害，用来让“受击会减少血量”的流程可以被测试。
# - contact_damage_cooldown：连续接触肉体时的伤害间隔，避免每帧扣血。
# - can_move：是否启用当前占位巡逻。关闭后敌人会停在 tscn 中摆放的位置。
# - current_health：敌人当前血量。降到 0 时敌人隐藏并停止碰撞。
# - contact_damage_timer：距离下一次允许接触伤害还剩多少秒。
# - visual_polygon：敌人的白模视觉节点引用。三个敌人场景可以编辑颜色与形状。
# - damage_area：敌人用于检测肉体接触的 Area2D。它不会挡住玩家专属摄像机边界。
# - _ready()：初始化血量、伤害区域和视觉样式。
# - _physics_process(delta)：执行简单巡逻、场景碰撞反弹和接触伤害计时。
# - take_damage(amount)：供后续攻击牌调用的扣血入口。
# - _try_damage_body()：检查伤害区域内是否有肉体，有则按冷却扣血。
# - _refresh_visual_style()：根据敌人类型设置默认颜色，保证三类敌人有可辨认白模。
# - _disable_enemy()：敌人血量为 0 后关闭物理、监控和显示。

@export var enemy_type_id := 1
@export var move_speed := 90.0
@export var move_direction := Vector2.LEFT
@export var max_health := 30.0
@export var contact_damage := 10.0
@export var contact_damage_cooldown := 1.0
@export var can_move := true

var current_health := 30.0
var contact_damage_timer := 0.0

@onready var visual_polygon: Polygon2D = $Visual
@onready var damage_area: Area2D = $DamageArea


func _ready() -> void:
	current_health = max_health
	contact_damage_timer = 0.0
	if damage_area != null:
		damage_area.monitoring = true
	_refresh_visual_style()


func _physics_process(delta: float) -> void:
	contact_damage_timer = maxf(0.0, contact_damage_timer - delta)
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


func _try_damage_body() -> void:
	if contact_damage_timer > 0.0 or damage_area == null:
		return

	for body in damage_area.get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(contact_damage)
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
	set_collision_mask_value(3, false)
	if damage_area != null:
		damage_area.monitoring = false
