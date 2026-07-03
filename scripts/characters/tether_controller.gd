extends Node
class_name TetherController

signal body_quick_move_started

## 牵引控制器，负责灵魂与肉体之间的拉扯规则和反馈。

const TETHER_EPSILON = 0.001

## 引用玩家根节点。
var player_root
## 保存pull强化multiplier。
var pull_boost_multiplier = 1.0
## 记录pull强化的剩余值。
var pull_boost_remaining = 0.0
## 保存inertialdrag方向。
var inertial_drag_direction = Vector2.ZERO
## 记录inertialdrag速度。
var inertial_drag_speed = 0.0
## 记录inertialdrag距离的剩余值。
var inertial_drag_distance_remaining = 0.0
## 记录本次惯性拖拽接近最大牵引距离时的触发边距。
var inertial_drag_trigger_margin = 0.0
## 记录惯性拖拽是否已经正式开始。
var inertial_drag_started = false
## 记录当前是否处于 body 主导的牵引阶段。
var body_lead_active = false
## body 主导阶段还剩余的时间。
var body_lead_remaining = 0.0
## body 主导阶段在魂体距离回落到该值后结束。
var body_lead_release_distance = 0.0
## body 主导阶段是否真的把魂体距离拉开过释放线。
var body_lead_has_stretched = false
## 当前是否处于固定长度的契约状态。
var fixed_length_active = false
## 固定长度状态还剩余的时间。
var fixed_length_remaining = 0.0
## 契约锁定的魂体距离。
var fixed_length_distance = 0.0
## 契约使用的当前朝向。
var fixed_length_direction = Vector2.RIGHT
## 契约上一帧记录的灵魂位置。
var fixed_length_previous_soul_position = Vector2.ZERO
## 契约上一帧记录的肉体位置。
var fixed_length_previous_body_position = Vector2.ZERO
## 当前固定长度效果的拥有者标识。
var fixed_length_owner_id = 0
## 记录当前距离。
var current_distance = 0.0
## 记录当前tension比例。
var current_tension_ratio = 0.0
## 保存牵引线。
@onready var tether_line = $"../TetherLine"


## 在物理帧中处理移动、判定或同步逻辑。
func _physics_process(delta):
	if player_root == null:
		return

	var battle_delta = _get_battle_delta(delta)
	var battle_scale = _get_battle_time_scale()

	pull_boost_remaining = maxf(0.0, pull_boost_remaining - battle_delta)
	if pull_boost_remaining <= 0.0:
		pull_boost_multiplier = 1.0

	var soul = player_root.soul
	var body = player_root.body
	if soul == null or body == null:
		return

	var soul_scripted = soul.has_method("is_scripted_motion") and soul.is_scripted_motion()
	var body_scripted = body.has_method("is_scripted_motion") and body.is_scripted_motion()
	var soul_dashing = soul.has_method("is_dashing") and soul.is_dashing()
	var offset = soul.global_position - body.global_position
	var distance = offset.length()
	current_distance = distance
	current_tension_ratio = 0.0
	var dragged_by_inertia = false

	if inertial_drag_distance_remaining > 0.0 and not inertial_drag_started and not soul_scripted and not soul_dashing:
		_clear_inertial_drag()

	if fixed_length_active and fixed_length_remaining >= 0.0:
		fixed_length_remaining = maxf(0.0, fixed_length_remaining - battle_delta)
		if fixed_length_remaining <= 0.0:
			end_fixed_length_tether()

	if body_lead_active:
		body_lead_remaining = maxf(0.0, body_lead_remaining - battle_delta)
		if distance > body_lead_release_distance:
			body_lead_has_stretched = true
		if body_lead_remaining <= 0.0:
			if body_lead_has_stretched:
				if distance <= body_lead_release_distance:
					body_lead_active = false
					body_lead_has_stretched = false
			else:
				body_lead_active = false

	if inertial_drag_distance_remaining > 0.0 and not body_scripted:
		var max_distance = player_root.stats.max_tether_distance
		if inertial_drag_started or distance >= max_distance - inertial_drag_trigger_margin:
			if not inertial_drag_started:
				inertial_drag_started = true
				body_quick_move_started.emit()
			var step = minf(inertial_drag_distance_remaining, inertial_drag_speed * battle_delta)
			var collided = false
			if body.has_method("move_with_collision"):
				collided = body.move_with_collision(inertial_drag_direction * step)
			else:
				body.global_position += inertial_drag_direction * step
			body.velocity = Vector2.ZERO
			if collided:
				inertial_drag_distance_remaining = 0.0
			else:
				inertial_drag_distance_remaining -= step
			dragged_by_inertia = true

	if inertial_drag_distance_remaining <= 0.0:
		_clear_inertial_drag()

	if fixed_length_active:
		_apply_fixed_length_tether(soul, body)
		offset = soul.global_position - body.global_position
		distance = offset.length()
		current_distance = distance
		current_tension_ratio = _compute_tension_ratio(distance)
		_update_tether_visual(body, soul, soul_dashing)
		return

	if _apply_max_tether_constraint(soul, body, offset, distance):
		offset = soul.global_position - body.global_position
		distance = offset.length()
		current_distance = distance

	if distance > player_root.stats.soft_tether_distance and distance > 0.0:
		var ratio = _compute_tension_ratio(distance)
		current_tension_ratio = ratio
		if not body_scripted and not dragged_by_inertia and not soul_dashing and not body_lead_active:
			var pull_speed = player_root.stats.body_pull_speed * pull_boost_multiplier
			body.velocity = offset.normalized() * pull_speed * (0.4 + ratio * 0.6) * battle_scale
			body.move_and_slide()
		elif not body_scripted and not dragged_by_inertia:
			body.velocity = Vector2.ZERO
		if body_lead_active and not soul_scripted and not soul_dashing:
			var soul_pull_speed = player_root.stats.body_pull_speed * (0.75 + ratio * 0.9)
			var soul_motion = (-offset).normalized() * soul_pull_speed * battle_delta
			if soul.has_method("move_with_collision"):
				soul.move_with_collision(soul_motion)
			else:
				soul.global_position += soul_motion
			soul.velocity = Vector2.ZERO
			_set_soul_movement_scale(soul, 0.0)
		elif not soul_scripted and not soul_dashing:
			_set_soul_movement_scale(soul, lerpf(1.0, player_root.stats.dragged_movement_scale, ratio))
	elif not body_scripted:
		body.velocity = Vector2.ZERO

	_update_tether_visual(body, soul, soul_dashing)


## 临时提高肉体被拉扯时的跟随力度。
func begin_pull_boost(multiplier, duration):
	pull_boost_multiplier = maxf(1.0, multiplier)
	pull_boost_remaining = maxf(0.0, duration)


## 开始一段 body 主导的牵引阶段，持续一段时间或在魂体距离回落后结束。
func begin_body_lead(duration, release_distance):
	body_lead_active = true
	body_lead_remaining = maxf(0.0, duration)
	body_lead_release_distance = maxf(0.0, release_distance)
	body_lead_has_stretched = false


## 开始一段固定当前魂体长度的契约状态。
func begin_fixed_length_tether(duration, owner_id := 0):
	if player_root == null or player_root.soul == null or player_root.body == null:
		return
	var soul = player_root.soul
	var body = player_root.body
	var offset = soul.global_position - body.global_position
	fixed_length_active = true
	fixed_length_remaining = maxf(0.0, duration)
	if duration < 0.0:
		fixed_length_remaining = -1.0
	fixed_length_distance = offset.length()
	fixed_length_owner_id = owner_id
	if offset.length() > 0.001:
		fixed_length_direction = offset.normalized()
	else:
		var fallback_direction = player_root.get_movement_direction()
		fixed_length_direction = fallback_direction.normalized() if fallback_direction.length() > 0.001 else Vector2.RIGHT
	fixed_length_previous_soul_position = soul.global_position
	fixed_length_previous_body_position = body.global_position


## 结束当前固定长度的契约状态。
func end_fixed_length_tether(owner_id := 0):
	if owner_id != 0 and fixed_length_owner_id != 0 and fixed_length_owner_id != owner_id:
		return
	fixed_length_active = false
	fixed_length_remaining = 0.0
	fixed_length_owner_id = 0


## 返回当前是否有牵引控制器驱动的短时位移。
func is_scripted_motion_active():
	return inertial_drag_distance_remaining > 0.0 or body_lead_active


## 兼容 2844 worktree 的一次性运动查询命名。
func is_motion_primitive_active():
	return is_scripted_motion_active()


## 返回当前是否处于固定魂体间距状态。
func is_fixed_length_tether_active():
	return fixed_length_active


## 取消牵引控制器驱动的短时位移，不影响持续型固定间距效果。
func cancel_transient_motion():
	_clear_inertial_drag()
	body_lead_active = false
	body_lead_remaining = 0.0
	body_lead_release_distance = 0.0
	body_lead_has_stretched = false


## 兼容 2844 worktree 的一次性牵引运动取消命名。
func cancel_motion_primitives():
	cancel_transient_motion()


## 按固定长度规则同步灵魂与肉体的位置。
func _apply_fixed_length_tether(soul, body):
	var rod_direction = fixed_length_direction
	var previous_offset = fixed_length_previous_soul_position - fixed_length_previous_body_position
	if previous_offset.length() > 0.001:
		rod_direction = previous_offset.normalized()
	elif rod_direction.length() <= 0.001:
		rod_direction = Vector2.RIGHT

	var soul_delta = soul.global_position - fixed_length_previous_soul_position
	var body_target = body.global_position
	var soul_target = soul.global_position

	if fixed_length_distance <= 0.5:
		body_target += soul_delta
	else:
		var radial_amount = soul_delta.dot(rod_direction)
		body_target += rod_direction * radial_amount
		var tangent = Vector2(-rod_direction.y, rod_direction.x)
		var tangent_amount = soul_delta.dot(tangent)
		var rotated_offset = rod_direction * fixed_length_distance + tangent * tangent_amount
		if rotated_offset.length() <= 0.001:
			rotated_offset = rod_direction * fixed_length_distance
		fixed_length_direction = rotated_offset.normalized()

	var body_motion = body_target - body.global_position
	if body_motion.length() > 0.001:
		if body.has_method("move_with_collision"):
			body.move_with_collision(body_motion)
		else:
			body.global_position = body_target
	body.velocity = Vector2.ZERO

	if fixed_length_distance <= 0.5:
		soul_target = body.global_position
	else:
		soul_target = body.global_position + fixed_length_direction * fixed_length_distance

	var soul_motion = soul_target - soul.global_position
	if soul_motion.length() > 0.001:
		if soul.has_method("move_with_collision"):
			soul.move_with_collision(soul_motion)
		else:
			soul.global_position = soul_target

	var actual_offset = soul.global_position - body.global_position
	if actual_offset.length() > 0.001:
		fixed_length_direction = actual_offset.normalized()
	fixed_length_previous_soul_position = soul.global_position
	fixed_length_previous_body_position = body.global_position


## 将魂体实时限制在最大牵引长度内，防止任意脚本位移把弹簧拉坏。
func _apply_max_tether_constraint(soul, body, offset: Vector2, distance: float):
	if player_root == null or player_root.stats == null:
		return false
	var max_distance = maxf(0.0, player_root.stats.max_tether_distance)
	if max_distance <= TETHER_EPSILON or distance <= max_distance + TETHER_EPSILON:
		return false
	if offset.length() <= TETHER_EPSILON:
		return false

	var direction = offset.normalized()
	var overflow = distance - max_distance
	var soul_motion = -direction * overflow * 0.5
	var body_motion = direction * overflow * 0.5
	_move_tether_endpoint(soul, soul_motion)
	_move_tether_endpoint(body, body_motion)
	soul.velocity = Vector2.ZERO
	body.velocity = Vector2.ZERO
	return true


func _move_tether_endpoint(endpoint, motion: Vector2):
	if endpoint == null or motion.length() <= TETHER_EPSILON:
		return
	if endpoint.has_method("move_with_collision"):
		endpoint.move_with_collision(motion)
	else:
		endpoint.global_position += motion


func _set_soul_movement_scale(soul, value: float):
	if soul == null:
		return
	if soul.get("movement_scale") == null:
		return
	soul.movement_scale = value


func _get_battle_delta(delta):
	if not is_inside_tree():
		return delta
	var game_time = get_node_or_null("/root/GameTime")
	if game_time == null or not game_time.has_method("get_battle_delta"):
		return delta
	return game_time.get_battle_delta(delta)


func _get_battle_time_scale():
	if not is_inside_tree():
		return 1.0
	var game_time = get_node_or_null("/root/GameTime")
	if game_time == null or not game_time.has_method("get_battle_time_scale"):
		return 1.0
	return game_time.get_battle_time_scale()


## 返回当前距离对应的张力比例。
func _compute_tension_ratio(distance):
	if player_root == null or player_root.stats == null:
		return 0.0
	if distance <= player_root.stats.soft_tether_distance:
		return 0.0
	if player_root.stats.max_tether_distance <= player_root.stats.soft_tether_distance:
		return 1.0
	return inverse_lerp(
		player_root.stats.soft_tether_distance,
		player_root.stats.max_tether_distance,
		minf(distance, player_root.stats.max_tether_distance)
	)


## 更新当前牵引线可视状态。
func _update_tether_visual(body, soul, soul_dashing):
	if tether_line == null or not tether_line.has_method("set_tether_state"):
		return
	tether_line.set_tether_state(
		player_root.to_local(body.global_position),
		player_root.to_local(soul.global_position),
		current_tension_ratio,
		soul_dashing
	)


## 开始一次肉体惯性拖拽效果。
func begin_inertial_drag(direction, distance, duration, trigger_margin):
	_clear_inertial_drag()

	if distance <= 0.0 or direction.length() <= 0.001:
		return

	inertial_drag_direction = direction.normalized()
	inertial_drag_distance_remaining = distance
	inertial_drag_speed = distance / maxf(0.001, duration)
	inertial_drag_trigger_margin = maxf(0.0, trigger_margin)


func _clear_inertial_drag():
	inertial_drag_direction = Vector2.ZERO
	inertial_drag_speed = 0.0
	inertial_drag_distance_remaining = 0.0
	inertial_drag_trigger_margin = 0.0
	inertial_drag_started = false


## 返回当前牵引状态的调试快照。
func get_debug_snapshot():
	return {
		"distance": current_distance,
		"ratio": current_tension_ratio,
		"inertia_remaining": inertial_drag_distance_remaining,
		"inertia_direction": inertial_drag_direction,
		"body_lead_active": body_lead_active,
		"body_lead_remaining": body_lead_remaining,
		"fixed_length_active": fixed_length_active,
		"fixed_length_remaining": fixed_length_remaining,
		"fixed_length_distance": fixed_length_distance,
	}
