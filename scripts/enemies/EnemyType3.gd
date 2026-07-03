extends RangedEnemyBase

class_name EnemyType3

# 脚本说明：
# - bullet：远程敌人发射的子弹场景。
# - bullet_speed：子弹初速度。
# - bullet_damage：子弹命中肉体时造成的伤害。
# - shoot_interval：连续射击之间的间隔。
# - shoot_range：敌人与肉体距离小于该值时停下并射击。
# - is_elite：是否为精英形态。精英形态一次发射两颗平行子弹。
# - elite_bullet_offset：精英形态两颗子弹相对中心点的偏移距离。
# - can_shoot：当前是否允许发射下一轮子弹。
# - _ready()：调用基类初始化并启动行为循环。
# - start_behavior_loop()：按物理帧追踪肉体、移动、冻结和射击。
# - shoot(dir)：执行一次射击并等待射击间隔。
# - spawn_bullet(pos, dir)：实例化子弹，把伤害和来源敌人传给子弹。

@export var bullet: PackedScene
@export var bullet_speed: float = 200
@export var bullet_damage: int = 5
@export var shoot_interval: float = 3
@export var shoot_range: float = 300
@export var is_elite: bool
@export var elite_bullet_offset = 20

var can_shoot = true

func _ready() -> void:
	super._ready()
	start_behavior_loop()

func start_behavior_loop():
	var core = EnemyUtils.get_body_core()
	while true:
		await get_tree().physics_frame
		if not is_instance_valid(core) or not is_inside_tree():
			return
		if is_card_frozen():
			move_direction = Vector2.ZERO
			continue
		var dir = core.global_position - global_position
		if dir.length() > shoot_range:
			move_direction = EnemyUtils.force_left(dir.normalized())
		else:
			move_direction = Vector2.ZERO
			if can_shoot:
				shoot(dir)

func shoot(dir: Vector2):
	assert(can_shoot)
	can_shoot = false
	if is_card_frozen():
		can_shoot = true
		return
	var pos = global_position
	dir = dir.normalized()
	if is_elite:
		var dir1 = Vector2(dir.y, -dir.x)
		spawn_bullet(pos+dir1*elite_bullet_offset, dir)
		spawn_bullet(pos-dir1*elite_bullet_offset, dir)
	else:
		spawn_bullet(pos, dir)
	await get_tree().create_timer(shoot_interval).timeout
	can_shoot = true

func spawn_bullet(pos: Vector2, dir: Vector2):
	var obj = bullet.instantiate() as Bullet
	obj.global_position = pos
	obj.linear_velocity = dir * bullet_speed
	obj.damage = bullet_damage
	obj.source_enemy = self
	EnemyUtils.get_main_scene().add_child(obj)
