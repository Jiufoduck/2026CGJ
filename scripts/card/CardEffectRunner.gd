extends Node
class_name CardEffectRunner

# 脚本说明：
# - CardDeckScript：牌堆脚本预加载，用于读取词条常量和牌堆工具方法。
# - CardCatalogScript：卡牌目录预加载，用于恢复生成效果创建恢复牌。
# - CounterProjectileScene：A3 反杀怪物的短暂弹道反馈场景。
# - CardFeedbackEffectScript：白模卡牌反馈脚本，用于环形、扫光、标记和连线反馈。
# - CardBurnDissolveEffectScript：消耗牌打出后使用的高分辨率随机烧洞溶解反馈。
# - CardProjectileLineScript：A3 弹道反馈脚本，用于 Try again 时清理残留弹道。
# - controller：主控制器引用。效果执行器通过它访问玩家、肉体、相机、HUD 和牌堆。
# - rng：卡牌随机数发生器。奖励池以外的随机效果，例如 B10 优化手牌，会使用它。
# - collision_charge_player_id：A2 当前拥有撞击怪物状态的玩家编号。0 表示没有该状态。
# - collision_charge_damage：A2 撞击怪物时造成的基础伤害。
# - collision_charge_radius：A2 判定撞到怪物的距离半径。
# - collision_charge_hit_cooldown：A2 同一敌人两次受撞击伤害之间的最短间隔。
# - collision_charge_hit_cooldowns：A2 当前持续期间每个敌人的剩余命中冷却。冷却归零后可再次受伤。
# - collision_charge_feedback：A2 持续期间跟随玩家的白模反馈节点。
# - counterattack_active：A3 反杀怪物是否正在等待下一只攻击肉体的怪物。
# - counterattack_lifetime：A3 弹道反馈存在时间。
# - counterattack_feedback：A3 等待反杀期间跟随肉体的白模反馈节点。
# - phase_walk_active：A6 穿墙状态是否正在断线期间生效。
# - phase_walk_feedbacks：A6 穿墙期间跟随两名玩家的白模反馈节点。
# - group_freeze_active：B9 群体冻结状态是否正在断线期间生效。
# - group_freeze_feedback：B9 冻结触发时的摄像机范围反馈节点。
# - focused_fire_owner_id：B11 集中火力中无法出牌的玩家编号。0 表示未生效。
# - focused_fire_ally_id：B11 集中火力中获得 0.5 秒 CD 的另一位玩家编号。
# - focused_fire_cooldown：B11 给另一位玩家固定的 CD。
# - focused_fire_feedbacks：B11 状态持续期间跟随两名玩家的白模反馈节点。
# - next_damage_multiplier_by_player：B12 给每名玩家下一次数值伤害保存的倍率。
# - setup(new_controller)：绑定主控制器并连接肉体断线/恢复/受击信号。
# - can_player_play(player_id)：判断玩家是否被 B11 禁止打牌。
# - is_card_playable(card_data)：判断当前连线状态下这张牌能否打出。
# - get_play_cooldown(player_id, card_data)：返回成功打出这张牌后应设置的 CD。
# - get_pass_cooldown(player_id, card_data)：返回跳过这张牌后应设置的 CD；非法牌跳过为 0。
# - on_card_success_started(player_id, card_data)：某张牌成功打出时，先取消“到下一张牌前”的旧状态。
# - on_card_passed(player_id, card_data)：某张牌被跳过时，处理 B11 的跳过 CD 规则。
# - apply_card(player_id, card_data)：根据 effect_id 分发并执行具体卡牌效果。
# - apply_player_damage_multiplier(player_id, amount)：给某名玩家造成的下一次数值伤害应用并消耗 B12 倍率。
# - reset_all_effects()：Try again 时清理所有持续卡牌状态和残留反馈。
# - _physics_process(delta)：每帧处理 A2 撞击检测，并维持 B9 对新生成敌人的冻结。
# - _apply_*：每个具体卡牌效果的实现。
# - _on_body_damaged_by_enemy(amount, source_enemy)：A3 监听肉体受击来源并反杀敌人。
# - _on_link_broken_started(seconds_left)：断线发生时结束 B11 集中火力。
# - _on_link_restored()：恢复连线时清理 A6 穿墙和 B9 冻结。
# - _spawn_*：创建白模反馈节点。
# - _spawn_consumable_dissolve(player_id, card_data)：为成功打出的消耗牌生成烧洞溶解卡片反馈。
# - _clear_transient_effect_nodes()：清掉 CardEffectRunner 创建在主控制器下的临时视觉节点。
# - _overwhelm_enemy(enemy, direction, distance, decay)：优先调用 EnemyBase._on_overwhelmed 执行击退。
# - _get_*：查找玩家、牌堆、敌人、相机视野等通用辅助方法。

const CardDeckScript = preload("res://scripts/card/CardDeck.gd")
const CardCatalogScript = preload("res://scripts/card/CardCatalog.gd")
const CounterProjectileScene = preload("res://scenes/effects/CardProjectileLine.tscn")
const CardFeedbackEffectScript = preload("res://scripts/effects/CardFeedbackEffect.gd")
const CardBurnDissolveEffectScript = preload("res://scripts/effects/CardBurnDissolveEffect.gd")
const CardProjectileLineScript = preload("res://scripts/effects/CardProjectileLine.gd")

var controller
var rng := RandomNumberGenerator.new()
var collision_charge_player_id := 0
var collision_charge_damage := 0.0
var collision_charge_radius := 48.0
var collision_charge_hit_cooldown := 0.35
var collision_charge_hit_cooldowns := {}
var collision_charge_feedback
var counterattack_active := false
var counterattack_lifetime := 0.35
var counterattack_feedback
var phase_walk_active := false
var phase_walk_feedbacks: Array = []
var group_freeze_active := false
var group_freeze_feedback
var focused_fire_owner_id := 0
var focused_fire_ally_id := 0
var focused_fire_cooldown := 0.5
var focused_fire_feedbacks: Array = []
var next_damage_multiplier_by_player := {
	1: 1.0,
	2: 1.0,
}


func setup(new_controller) -> void:
	controller = new_controller
	rng.randomize()
	if controller.body_core.has_signal("damaged_by_enemy"):
		controller.body_core.damaged_by_enemy.connect(_on_body_damaged_by_enemy)
	controller.body_core.link_broken_started.connect(_on_link_broken_started)
	controller.body_core.link_restored.connect(_on_link_restored)


func can_player_play(player_id: int) -> bool:
	return focused_fire_owner_id != player_id


func is_card_playable(card_data: Dictionary) -> bool:
	if card_data.is_empty() or controller == null:
		return false

	var link_is_active: bool = controller.body_core.is_link_active()
	if CardDeckScript.card_has_tag(card_data, CardDeckScript.TAG_RESTORE) and link_is_active:
		return false
	if CardDeckScript.card_has_tag(card_data, CardDeckScript.TAG_BREAK_LINK) and not link_is_active:
		return false
	return true


func get_play_cooldown(player_id: int, card_data: Dictionary) -> float:
	if focused_fire_ally_id == player_id:
		return focused_fire_cooldown
	return float(card_data.get("base_cooldown", CardDeckScript.PLAY_COOLDOWN_SECONDS))


func get_pass_cooldown(player_id: int, card_data: Dictionary) -> float:
	if not is_card_playable(card_data):
		return 0.0
	if focused_fire_ally_id == player_id:
		return focused_fire_cooldown
	return CardDeckScript.PASS_COOLDOWN_SECONDS


func on_card_success_started(_player_id: int, _card_data: Dictionary) -> void:
	_end_collision_charge()
	_end_counterattack()


func on_card_passed(_player_id: int, _card_data: Dictionary) -> void:
	pass


func apply_card(player_id: int, card_data: Dictionary) -> void:
	var effect_id := str(card_data.get("effect_id", ""))
	if CardDeckScript.card_is_consumable(card_data):
		_spawn_consumable_dissolve(player_id, card_data)
	match effect_id:
		"range_damage":
			_apply_range_damage(player_id, card_data)
		"collision_charge":
			_apply_collision_charge(player_id, card_data)
		"counterattack":
			_apply_counterattack(card_data)
		"clear_screen":
			_apply_clear_screen(card_data)
		"restore_generation":
			_apply_restore_generation(player_id, card_data)
		"phase_walk":
			_apply_phase_walk(card_data)
		"knockback":
			_apply_knockback(player_id, card_data)
		"cd_distribution":
			_apply_cd_distribution(player_id, card_data)
		"group_freeze":
			_apply_group_freeze()
		"optimize_hand":
			_apply_optimize_hand(player_id, card_data)
		"focused_fire":
			_apply_focused_fire(player_id, card_data)
		"damage_boost":
			_apply_damage_boost(player_id, card_data)
		"restore_link":
			_apply_restore_link()


func apply_player_damage_multiplier(player_id: int, amount: float) -> float:
	if amount <= 0.0:
		return amount

	var multiplier: float = float(next_damage_multiplier_by_player.get(player_id, 1.0))
	if multiplier <= 1.0:
		return amount

	next_damage_multiplier_by_player[player_id] = 1.0
	return amount * multiplier


func reset_all_effects() -> void:
	if controller == null or not is_instance_valid(controller):
		return

	_end_collision_charge()
	_end_counterattack()
	if phase_walk_active:
		for player in [controller.player_one, controller.player_two]:
			if player.has_method("set_wall_phase_enabled"):
				player.set_wall_phase_enabled(false)
	phase_walk_active = false
	_clear_feedback_array(phase_walk_feedbacks)

	if group_freeze_active:
		_set_all_enemies_frozen(false)
	group_freeze_active = false
	_free_feedback(group_freeze_feedback)
	group_freeze_feedback = null

	_end_focused_fire()
	next_damage_multiplier_by_player = {
		1: 1.0,
		2: 1.0,
	}
	_clear_transient_effect_nodes()


func _physics_process(delta: float) -> void:
	if collision_charge_player_id != 0:
		_apply_collision_charge_hits(delta)
	if group_freeze_active:
		_set_all_enemies_frozen(true)


func _apply_range_damage(player_id: int, card_data: Dictionary) -> void:
	var base_damage: float = float(card_data.get("damage_amount", 0.0))
	var damage: float = apply_player_damage_multiplier(player_id, base_damage)
	var radius: float = controller.player_one.global_position.distance_to(controller.player_two.global_position) * 0.5
	var center: Vector2 = controller.body_core.global_position
	_spawn_ring(center, radius, Color(1.0, 0.16, 0.10, 1.0), "范围伤害")
	for enemy in _get_alive_enemies(false):
		if enemy.global_position.distance_to(center) <= radius and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			_spawn_marker(enemy.global_position, 30.0, Color(1.0, 0.25, 0.12, 1.0), "-%s" % _format_amount(damage), 0.45)
	controller.body_core.take_hit(damage)
	_spawn_marker(center, 38.0, Color(1.0, 0.25, 0.12, 1.0), "肉体 -%s" % _format_amount(damage), 0.5)


func _apply_collision_charge(player_id: int, card_data: Dictionary) -> void:
	collision_charge_player_id = player_id
	collision_charge_damage = float(card_data.get("enemy_damage_amount", 0.0))
	collision_charge_radius = float(card_data.get("hit_radius", 48.0))
	collision_charge_hit_cooldown = maxf(0.0, float(card_data.get("hit_cooldown", 0.35)))
	collision_charge_hit_cooldowns.clear()
	var player := _get_player(player_id)
	if player != null and player.has_method("set_move_speed_multiplier"):
		player.set_move_speed_multiplier(float(card_data.get("move_speed_scale", 1.0)))
	if player != null:
		_free_feedback(collision_charge_feedback)
		collision_charge_feedback = _spawn_follow_marker(player, 46.0, Color(1.0, 0.82, 0.12, 1.0), "撞击")


func _apply_counterattack(card_data: Dictionary) -> void:
	counterattack_active = true
	counterattack_lifetime = float(card_data.get("projectile_lifetime", 0.35))
	_free_feedback(counterattack_feedback)
	counterattack_feedback = _spawn_follow_marker(controller.body_core, 54.0, Color(0.9, 0.35, 1.0, 1.0), "反杀待机")


func _apply_clear_screen(card_data: Dictionary) -> void:
	var push_distance: float = float(card_data.get("push_distance", 0.0))
	var overwhelm_decay: float = float(card_data.get("overwhelm_decay", 0.72))
	_spawn_sweep(_get_camera_world_rect(), Vector2.LEFT, Color(0.3, 0.9, 1.0, 1.0), "清场")
	for enemy in _get_alive_enemies(true):
		_overwhelm_enemy(enemy, Vector2.LEFT, push_distance, overwhelm_decay)
		_spawn_marker(enemy.global_position, 24.0, Color(0.3, 0.9, 1.0, 1.0), "←", 0.35)


func _apply_restore_generation(player_id: int, card_data: Dictionary) -> void:
	_spawn_ring(controller.body_core.global_position, 96.0, Color(0.15, 1.0, 0.45, 1.0), "恢复生成")
	controller.body_core.force_break_link()
	_add_restore_cards(player_id, int(card_data.get("restore_cards_to_add", 0)))
	var player := _get_player(player_id)
	if player != null:
		_spawn_marker(player.global_position, 52.0, Color(0.15, 1.0, 0.45, 1.0), "+恢复牌", 0.75)


func _apply_phase_walk(_card_data: Dictionary) -> void:
	_spawn_ring(controller.body_core.global_position, 88.0, Color(0.25, 0.85, 1.0, 1.0), "断裂穿墙")
	controller.body_core.force_break_link()
	phase_walk_active = true
	_clear_feedback_array(phase_walk_feedbacks)
	for player in [controller.player_one, controller.player_two]:
		if player.has_method("set_wall_phase_enabled"):
			player.set_wall_phase_enabled(true)
		phase_walk_feedbacks.append(_spawn_follow_marker(player, 44.0, Color(0.25, 0.85, 1.0, 1.0), "穿墙"))


func _apply_knockback(player_id: int, card_data: Dictionary) -> void:
	var knockback_distance: float = float(card_data.get("knockback_distance", 0.0))
	var overwhelm_decay: float = float(card_data.get("overwhelm_decay", 0.72))
	var center: Vector2 = controller.body_core.global_position
	_spawn_ring(center, knockback_distance, Color(1.0, 0.45, 0.1, 1.0), "击退")
	for enemy in _get_alive_enemies(true):
		var direction: Vector2 = enemy.global_position - center
		if direction.length() <= 0.001:
			direction = Vector2.RIGHT
		else:
			direction = direction.normalized()
		_overwhelm_enemy(enemy, direction, knockback_distance, overwhelm_decay)
		_spawn_line(center, enemy.global_position, Color(1.0, 0.45, 0.1, 1.0), "", 0.24)
		_spawn_marker(enemy.global_position, 26.0, Color(1.0, 0.45, 0.1, 1.0), "击退", 0.35)

	var body_damage: float = apply_player_damage_multiplier(player_id, float(card_data.get("body_damage_amount", 0.0)))
	controller.body_core.take_hit(body_damage)
	_spawn_marker(center, 40.0, Color(1.0, 0.2, 0.1, 1.0), "肉体 -%s" % _format_amount(body_damage), 0.55)


func _apply_cd_distribution(player_id: int, card_data: Dictionary) -> void:
	var player := _get_player(player_id)
	var other_player := _get_player(_get_other_player_id(player_id))
	if player != null and other_player != null:
		_spawn_line(player.global_position, other_player.global_position, Color(0.45, 0.7, 1.0, 1.0), "CD 分配", 0.65)
		_spawn_marker(player.global_position, 42.0, Color(1.0, 0.25, 0.25, 1.0), "CD x%s" % _format_amount(float(card_data.get("cooldown_self_multiplier", 1.0))), 0.75)
		_spawn_marker(other_player.global_position, 42.0, Color(0.25, 0.8, 1.0, 1.0), "CD x%s" % _format_amount(float(card_data.get("cooldown_other_multiplier", 1.0))), 0.75)
	controller.body_core.force_break_link()
	var own_deck = _get_deck(player_id)
	var other_deck = _get_deck(_get_other_player_id(player_id))
	if own_deck != null:
		own_deck.multiply_cooldown(float(card_data.get("cooldown_self_multiplier", 1.0)))
	if other_deck != null:
		other_deck.multiply_cooldown(float(card_data.get("cooldown_other_multiplier", 1.0)))


func _apply_group_freeze() -> void:
	_free_feedback(group_freeze_feedback)
	group_freeze_feedback = _spawn_sweep(_get_camera_world_rect(), Vector2.DOWN, Color(0.35, 0.9, 1.0, 1.0), "群体冻结", 1.1)
	controller.body_core.force_break_link()
	group_freeze_active = true
	_set_all_enemies_frozen(true)
	for enemy in _get_alive_enemies(false):
		_spawn_marker(enemy.global_position, 22.0, Color(0.35, 0.9, 1.0, 1.0), "冻结", 0.55)


func _apply_optimize_hand(player_id: int, card_data: Dictionary) -> void:
	_add_restore_cards(player_id, int(card_data.get("restore_cards_to_add", 0)))
	var deck = _get_deck(player_id)
	if deck != null:
		var optimized_card: Dictionary = deck.make_random_consumable_card_free(rng)
		var player := _get_player(player_id)
		if player != null:
			_spawn_marker(player.global_position, 52.0, Color(0.3, 1.0, 0.45, 1.0), "+恢复", 0.6)
			var optimized_name := str(optimized_card.get("name", "无消耗牌"))
			_spawn_marker(player.global_position + Vector2(0.0, 56.0), 42.0, Color(1.0, 0.9, 0.25, 1.0), "优化 %s" % optimized_name, 0.85)


func _apply_focused_fire(player_id: int, card_data: Dictionary) -> void:
	focused_fire_owner_id = player_id
	focused_fire_ally_id = _get_other_player_id(player_id)
	focused_fire_cooldown = float(card_data.get("focused_ally_cooldown", 0.5))
	_clear_feedback_array(focused_fire_feedbacks)
	var owner := _get_player(focused_fire_owner_id)
	var ally := _get_player(focused_fire_ally_id)
	if owner != null:
		focused_fire_feedbacks.append(_spawn_follow_marker(owner, 46.0, Color(1.0, 0.2, 0.2, 1.0), "禁牌"))
	if ally != null:
		focused_fire_feedbacks.append(_spawn_follow_marker(ally, 46.0, Color(1.0, 0.9, 0.15, 1.0), "0.5s"))
	if owner != null and ally != null:
		_spawn_line(owner.global_position, ally.global_position, Color(1.0, 0.9, 0.15, 1.0), "集中火力", 0.65)


func _apply_damage_boost(player_id: int, card_data: Dictionary) -> void:
	var player := _get_player(player_id)
	var other_player := _get_player(_get_other_player_id(player_id))
	controller.body_core.force_break_link()
	var other_player_id := _get_other_player_id(player_id)
	var deck = _get_deck(player_id)
	var card_count := 0
	if deck != null:
		card_count = deck.card_count()
	var multiplier := pow(float(card_data.get("damage_multiplier_base", 2.0)), card_count)
	next_damage_multiplier_by_player[other_player_id] = float(next_damage_multiplier_by_player.get(other_player_id, 1.0)) * multiplier
	if player != null and other_player != null:
		_spawn_line(player.global_position, other_player.global_position, Color(0.85, 0.35, 1.0, 1.0), "增伤 x%s" % _format_amount(multiplier), 0.85)
		_spawn_marker(other_player.global_position, 56.0, Color(0.85, 0.35, 1.0, 1.0), "下一伤害 x%s" % _format_amount(multiplier), 1.0)


func _apply_restore_link() -> void:
	_spawn_line(controller.player_one.global_position, controller.player_two.global_position, Color(0.25, 1.0, 0.45, 1.0), "恢复连线", 0.75)
	_spawn_ring(controller.body_core.global_position, 120.0, Color(0.25, 1.0, 0.45, 1.0), "满血重连")
	controller.body_core.restore_link()


func _apply_collision_charge_hits(delta: float) -> void:
	var player := _get_player(collision_charge_player_id)
	if player == null:
		_end_collision_charge()
		return

	_tick_collision_charge_hit_cooldowns(delta)
	for enemy in _get_alive_enemies(false):
		var enemy_id: int = enemy.get_instance_id()
		if float(collision_charge_hit_cooldowns.get(enemy_id, 0.0)) > 0.0:
			continue
		if player.global_position.distance_to(enemy.global_position) <= collision_charge_radius:
			collision_charge_hit_cooldowns[enemy_id] = collision_charge_hit_cooldown
			var damage := apply_player_damage_multiplier(collision_charge_player_id, collision_charge_damage)
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				_spawn_marker(enemy.global_position, 30.0, Color(1.0, 0.82, 0.12, 1.0), "-%s" % _format_amount(damage), 0.4)
				_spawn_line(player.global_position, enemy.global_position, Color(1.0, 0.82, 0.12, 1.0), "", 0.22)


func _tick_collision_charge_hit_cooldowns(delta: float) -> void:
	if collision_charge_hit_cooldowns.is_empty():
		return

	for enemy_id in collision_charge_hit_cooldowns.keys():
		var remaining := maxf(0.0, float(collision_charge_hit_cooldowns[enemy_id]) - delta)
		if remaining <= 0.0:
			collision_charge_hit_cooldowns.erase(enemy_id)
		else:
			collision_charge_hit_cooldowns[enemy_id] = remaining


func _add_restore_cards(player_id: int, amount: int) -> void:
	var deck = _get_deck(player_id)
	if deck == null:
		return
	for _index in range(maxi(0, amount)):
		deck.add_card(CardCatalogScript.make_restore_card())


func _on_body_damaged_by_enemy(_amount: float, source_enemy: Node) -> void:
	if not counterattack_active or source_enemy == null or not is_instance_valid(source_enemy):
		return

	_spawn_counter_projectile(source_enemy)
	if source_enemy.has_method("force_defeat"):
		source_enemy.force_defeat()
	counterattack_active = false


func _on_link_broken_started(_seconds_left: float) -> void:
	_end_focused_fire()


func _on_link_restored() -> void:
	if phase_walk_active:
		for player in [controller.player_one, controller.player_two]:
			if player.has_method("set_wall_phase_enabled"):
				player.set_wall_phase_enabled(false)
		_clear_feedback_array(phase_walk_feedbacks)
		phase_walk_active = false

	if group_freeze_active:
		_set_all_enemies_frozen(false)
		_free_feedback(group_freeze_feedback)
		group_freeze_feedback = null
		group_freeze_active = false


func _end_collision_charge() -> void:
	if collision_charge_player_id == 0:
		return

	var player := _get_player(collision_charge_player_id)
	if player != null and player.has_method("set_move_speed_multiplier"):
		player.set_move_speed_multiplier(1.0)
	collision_charge_player_id = 0
	collision_charge_damage = 0.0
	collision_charge_radius = 48.0
	collision_charge_hit_cooldown = 0.35
	collision_charge_hit_cooldowns.clear()
	_free_feedback(collision_charge_feedback)
	collision_charge_feedback = null


func _end_counterattack() -> void:
	counterattack_active = false
	_free_feedback(counterattack_feedback)
	counterattack_feedback = null


func _end_focused_fire() -> void:
	focused_fire_owner_id = 0
	focused_fire_ally_id = 0
	focused_fire_cooldown = 0.5
	_clear_feedback_array(focused_fire_feedbacks)


func _spawn_counter_projectile(source_enemy: Node) -> void:
	var projectile = CounterProjectileScene.instantiate()
	controller.add_child(projectile)
	if projectile.has_method("play"):
		projectile.play(controller.body_core.global_position, source_enemy.global_position, counterattack_lifetime)


func _spawn_ring(center: Vector2, radius: float, color: Color, label: String, lifetime := 0.55):
	var feedback = _make_feedback()
	if feedback == null:
		return null
	feedback.setup_ring(center, radius, color, lifetime, label)
	return feedback


func _spawn_marker(center: Vector2, radius: float, color: Color, label: String, lifetime := 0.65):
	var feedback = _make_feedback()
	if feedback == null:
		return null
	feedback.setup_marker(center, radius, color, lifetime, label)
	return feedback


func _spawn_follow_marker(target: Node2D, radius: float, color: Color, label: String):
	var feedback = _spawn_marker(target.global_position, radius, color, label, -1.0)
	if feedback != null:
		feedback.set_follow_node(target)
	return feedback


func _spawn_line(start: Vector2, finish: Vector2, color: Color, label: String, lifetime := 0.45):
	var feedback = _make_feedback()
	if feedback == null:
		return null
	feedback.setup_line(start, finish, color, lifetime, label)
	return feedback


func _spawn_sweep(world_rect: Rect2, direction: Vector2, color: Color, label: String, lifetime := 0.55):
	var feedback = _make_feedback()
	if feedback == null:
		return null
	feedback.setup_sweep(world_rect, direction, color, lifetime, label)
	return feedback


func _make_feedback():
	if controller == null or not is_instance_valid(controller):
		return null

	var feedback = CardFeedbackEffectScript.new()
	feedback.z_index = 2000
	controller.add_child(feedback)
	return feedback


func _spawn_consumable_dissolve(player_id: int, card_data: Dictionary) -> void:
	if controller == null or not is_instance_valid(controller):
		return

	var player := _get_player(player_id)
	var origin: Vector2 = controller.body_core.global_position
	if player != null:
		origin = player.global_position

	var dissolve_effect = CardBurnDissolveEffectScript.new()
	dissolve_effect.z_index = 2300
	controller.add_child(dissolve_effect)
	dissolve_effect.play(
		card_data,
		origin + Vector2(0.0, -96.0),
		rng.randf_range(1.0, 100000.0)
	)


func _free_feedback(feedback) -> void:
	if feedback != null and is_instance_valid(feedback):
		feedback.queue_free()


func _clear_feedback_array(feedbacks: Array) -> void:
	for feedback in feedbacks:
		_free_feedback(feedback)
	feedbacks.clear()


func _clear_transient_effect_nodes() -> void:
	if controller == null or not is_instance_valid(controller):
		return

	for child in controller.get_children():
		if not is_instance_valid(child) or child.is_queued_for_deletion():
			continue
		var child_script = child.get_script()
		if (
			child_script == CardFeedbackEffectScript
			or child_script == CardBurnDissolveEffectScript
			or child_script == CardProjectileLineScript
		):
			child.queue_free()


func _overwhelm_enemy(enemy: Node, direction: Vector2, distance: float, decay: float) -> void:
	if distance <= 0.0 or direction.is_zero_approx():
		return

	var normalized_direction := direction.normalized()
	var clamped_decay := clampf(decay, 0.0, 0.98)
	var overwhelm_speed := _distance_to_overwhelm_speed(distance, clamped_decay)
	if enemy.has_method("_on_overwhelmed"):
		enemy.call("_on_overwhelmed", normalized_direction, overwhelm_speed, clamped_decay)
	elif enemy.has_method("apply_knockback"):
		enemy.apply_knockback(normalized_direction * distance)
	elif enemy is Node2D:
		enemy.global_position += normalized_direction * distance


func _distance_to_overwhelm_speed(distance: float, decay: float) -> float:
	var ticks_per_second := float(Engine.physics_ticks_per_second)
	return distance * maxf(0.02, 1.0 - decay) * ticks_per_second


func _format_amount(amount: float) -> String:
	var rounded := roundf(amount)
	if is_equal_approx(amount, rounded):
		return str(int(rounded))
	return "%.1f" % amount


func _set_all_enemies_frozen(enabled: bool) -> void:
	for enemy in _get_alive_enemies(false):
		if enemy.has_method("set_card_frozen"):
			enemy.set_card_frozen(enabled)


func _get_alive_enemies(only_in_camera_view: bool) -> Array:
	var enemies: Array = []
	var camera_rect := _get_camera_world_rect()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy.has_method("is_alive") and not enemy.is_alive():
			continue
		if only_in_camera_view and not camera_rect.has_point(enemy.global_position):
			continue
		enemies.append(enemy)
	return enemies


func _get_camera_world_rect() -> Rect2:
	var half_size: Vector2 = controller.camera_view_size * 0.5
	return Rect2(controller.camera.global_position - half_size, controller.camera_view_size)


func _get_player(player_id: int) -> Node:
	if player_id == 1:
		return controller.player_one
	if player_id == 2:
		return controller.player_two
	return null


func _get_deck(player_id: int):
	if controller.decks_by_player.has(player_id):
		return controller.decks_by_player[player_id]
	return null


func _get_other_player_id(player_id: int) -> int:
	if player_id == 1:
		return 2
	return 1
