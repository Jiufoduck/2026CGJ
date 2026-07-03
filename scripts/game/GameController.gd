extends Node2D
class_name GameController

# 脚本说明：
# - ACTION_P1_PLAY_CARD：玩家 1 打出当前牌的输入动作名。脚本会在运行时保证默认按键存在。
# - ACTION_P1_PASS_CARD：玩家 1 选择不打出当前牌的输入动作名。当前牌会放到牌堆底部并进入 2 秒冷却。
# - ACTION_P2_PLAY_CARD：玩家 2 打出当前牌的输入动作名。脚本会在运行时保证默认按键存在。
# - ACTION_P2_PASS_CARD：玩家 2 选择不打出当前牌的输入动作名。当前牌会放到牌堆底部并进入 2 秒冷却。
# - OPPOSING_INPUT_DOT：判断两个玩家是否几乎反向用力的点乘阈值。它只用于识别正在把连线拉开的状态，不会让两人立刻静止。
# - SHARED_INPUT_DOT：判断两个玩家是否基本同向移动的点乘阈值。达到阈值时优先保留共同移动速度，满足“共同移动不会有阻力”。
# - CardDeckScript：显式预加载牌堆脚本，用于创建两个玩家的独立牌堆。
# - CardCatalogScript：显式预加载卡牌目录脚本，用于读取 13 张卡牌资源、初始牌组和玩家奖励池。
# - CardEffectRunnerScript：显式预加载卡牌效果执行器脚本，用于执行 13 张卡牌的实际效果。
# - player_one_path/player_two_path：两个玩家实例的 NodePath。角色本体放在 Player.tscn，主场景只引用实例。
# - body_core_path：肉体节点 NodePath。肉体碰撞体和视觉放在 BodyCore.tscn。
# - hud_path：HUD 节点 NodePath。UI 结构放在 HUD.tscn，脚本只更新文本和进度条。
# - camera_path：持续向右移动的 Camera2D 节点路径。
# - link_line_path：显示两名玩家与肉体连接关系的 Line2D 节点路径。
# - finish_line_path：视觉终点线节点路径。胜利结算读取这个节点的真实世界 x，而不是写死在脚本里。
# - level_length：主场景长条矩形的总长度。启动时会至少扩到右墙和 FinishLine 之后，用于摄像机和玩家边界。
# - level_height：主场景上下宽度。它比玩家最大连线长度更大，给上下任务点留出空间。
# - finish_line_margin：两个玩家都超过终点线右侧这个距离后，才判定抵达终点。
# - camera_scroll_speed：摄像机每秒向右推进的最低速度，满足“场景摄像机会一直往右移动”。
# - camera_follow_ahead：摄像机跟随两个玩家中心时向右预留的前视距离，避免玩家推进时贴在画面右侧。
# - camera_follow_lerp_speed：摄像机追向目标位置的插值速度。数值越大，自动跟随越紧。
# - camera_view_size：主视口可见区域尺寸，用于玩家专属边界限制；敌人不会使用这个限制。
# - camera_player_margin：玩家距离摄像机视野边缘的最小安全距离。
# - comfortable_link_length：连线无明显阻力的舒适长度。
# - maximum_link_length：连线最大长度。超出后阻力和位置修正快速增大。
# - taut_solo_mover_scale：只有一个玩家主动移动且连线拉紧时，主动玩家最低保留的速度比例，用来表达“拉动不动玩家会有阻力”。
# - taut_solo_follower_speed_share：只有一个玩家主动移动且连线拉紧时，被动玩家被拖向主动玩家的速度比例，用来表达玩家之间互相牵引。
# - outward_velocity_damping：连线拉紧时削弱“继续拉远”相对速度的强度。
# - spring_return_strength：玩家停止继续拉远后，连线把两人向舒适长度弹回的强度。
# - max_constraint_push_share：超过最大连线长度时，两名玩家各承担多少超长修正。0.5 表示两端平均回拉。
# - body_drag_resistance_start：肉体落后玩家连线中心超过这个距离后，玩家远离肉体的移动开始变重。
# - body_drag_resistance_full：肉体落后距离达到这个值时，远离肉体方向的阻力达到最大。
# - body_drag_min_away_speed_scale：阻力最大时，玩家远离肉体方向速度保留的最低比例。
# - body_drag_max_player_distance：任一玩家离肉体的最大允许距离，用来防止 net 或普通障碍卡肉体时玩家把距离拉到卡关。
# - body_drag_recoil_start：玩家离肉体超过这个距离，且没有继续远离肉体时，会开始被弹回。
# - body_drag_recoil_strength：玩家停止移动或往回走时，朝肉体回弹的强度。
# - player_one/player_two/body_core/hud/camera/link_line：运行时缓存的主节点引用，全部来自 tscn，不由脚本创建。
# - decks_by_player：两个玩家的独立牌堆字典。键为玩家编号，值为 CardDeck。
# - game_has_ended：游戏是否已经胜利或失败。结束后禁用玩家输入和卡牌输入。
# - reward_choice_active：当前是否正在等待玩家选择任务点奖励。为 true 时暂停游戏流程，只允许 HUD 奖励按钮响应。
# - card_effect_runner：运行时创建的卡牌效果执行器。它只负责逻辑，不承担场景结构；世界暂停时也要暂停效果检测。
# - _ready()：读取节点、注册输入、建立牌堆、连接任务点/肉体信号，把主世界相机同步给 HUD 的 SubViewport，并初始化 HUD。
# - _physics_process(delta)：每帧推进摄像机、移动、连线、卡牌冷却、任务终点和 HUD。
# - _ensure_default_input_actions()：注册默认键位，保证空项目运行时可以直接测试。
# - _register_key_action(action_name, physical_keycode)：把某个按键加入输入动作，避免 ProjectSettings 缺失时无输入。
# - _build_initial_decks()：按 CardCatalog 创建两个玩家各自 3 张、内容不同的初始牌堆。
# - _connect_task_points()：连接主场景中所有任务点的领取信号。
# - _sync_level_length_from_scene()：从 RightWall 和 FinishLine 推导关卡右边界，避免场景拉长后相机仍停在旧长度。
# - _get_finish_x()：读取 FinishLine 的多边形顶点，换算出世界坐标下的结算 x。
# - _handle_card_input()：处理玩家打牌和暂时不打牌。
# - _play_card_for_player(player_id)：处理非法出牌、牌堆移动、卡牌效果执行和 HUD 反馈。
# - _pass_card_for_player(player_id)：记录玩家选择不打出当前牌，把它放到牌堆底部，并按合法/非法状态设置冷却。
# - _advance_camera(delta, snap_to_target)：让摄像机自动跟随两个玩家中心，同时保持向右推进，并限制在主场景边界内。
# - _get_camera_target_position(delta)：计算摄像机本帧应追向的位置，综合玩家中心、前视距离、最低滚动速度和场景边界。
# - _move_players(delta)：读取两个玩家输入，并根据连线是否断开选择弹性连线移动或独立移动。
# - _get_player_move_speed(player)：读取玩家当前实际速度，支持 A2 临时移速倍率。
# - _calculate_linked_velocities(input_one, input_two)：按参考牵引控制器的软距离/张力思路计算速度；反向移动可继续拉开，只有达到最大长度才挡住继续拉远。
# - _get_body_drag_ratio()：肉体被 net 卡住并落后时，计算玩家远离肉体方向应承受的额外阻力比例。
# - _apply_body_drag_resistance(velocity, player_position, drag_ratio)：只削弱玩家远离肉体方向的速度，允许玩家正常回头靠近肉体。
# - _apply_body_drag_distance_constraint(delta, input_one, input_two)：限制玩家离肉体的最大距离，并在玩家不再外拉时把他们明显弹回。
# - _apply_single_player_body_drag_constraint(player, input_vector, delta)：对单个玩家执行肉体距离硬限制和停止回弹。
# - _apply_max_link_constraint()：超过最大连线长度时，迭代地把两名玩家投影回最大长度内；若一端被墙挡住，剩余修正会交给另一端。
# - _apply_link_spring_recoil(delta, input_one, input_two)：连线处于拉紧状态且玩家没有继续拉远时，把两端向舒适长度弹回一点。
# - _move_player_by_tether(player, motion)：对某个玩家施加连线修正位移，优先调用玩家脚本中的碰撞修正方法。
# - _get_tension_ratio(distance)：返回当前距离在舒适长度和最大长度之间的张力比例。
# - _inputs_are_opposing(input_one, input_two)：判断两个玩家是否正在反向用力，用来在最大长度附近加强“不可继续拉远”的限制。
# - _inputs_are_shared_direction(input_one, input_two)：判断两个玩家是否正在共同移动。
# - _clamp_players_to_camera()：把玩家限制在摄像机视野和场景矩形内，模拟玩家专属碰撞体积。
# - _separate_players_from_body()：额外防止两个玩家、玩家和肉体重叠，补足碰撞边界极端情况。
# - _update_body_and_line(delta, apply_net_strain, snap_to_center)：让肉体尝试回到两名玩家中点；如果被 net 挡住则停下，挣脱后用减速回弹运动回到中心。
# - _apply_net_strain(blocker, body_target, delta)：肉体被 net 挡住时，把拉扯距离传给 net；挣脱后给 HUD 一条反馈。
# - _update_hud()：集中刷新血量、连线状态、当前牌和牌堆数量。
# - _check_finish_condition()：两个玩家都抵达最右侧后结束游戏。
# - _end_game(message)：统一处理胜利或失败，关闭控制并显示结果。
# - _start_reward_choice(player_id, reward_cards)：打开任务点三选一奖励面板，暂停游戏并等待该玩家选择一张牌。
# - _finish_reward_choice(player_id, selected_card)：收到 HUD 选择结果后，把选中的卡加入对应玩家牌堆并恢复游戏。
# - _on_body_health_changed(current_health, max_health)：肉体血量变化时刷新 HUD。
# - _on_link_broken_started(seconds_left)：断线倒计时时刷新 HUD。
# - _on_link_restored()：恢复连线后刷新 HUD 和消息。
# - _on_game_over_requested()：断线超过 10 秒后结束游戏。
# - _on_task_point_claimed(point, player_id, reward_cards)：任务点被指定玩家拾取后，优先使用手动奖励；为空时从玩家奖励池随机生成 3 张牌。

const ACTION_P1_PLAY_CARD := "p1_play_card"
const ACTION_P1_PASS_CARD := "p1_pass_card"
const ACTION_P2_PLAY_CARD := "p2_play_card"
const ACTION_P2_PASS_CARD := "p2_pass_card"
const OPPOSING_INPUT_DOT := -0.65
const SHARED_INPUT_DOT := 0.65
const CardDeckScript = preload("res://scripts/card/CardDeck.gd")
const CardCatalogScript = preload("res://scripts/card/CardCatalog.gd")
const CardEffectRunnerScript = preload("res://scripts/card/CardEffectRunner.gd")

@export var player_one_path: NodePath = ^"Actors/PlayerOne"
@export var player_two_path: NodePath = ^"Actors/PlayerTwo"
@export var body_core_path: NodePath = ^"Actors/BodyCore"
@export var hud_path: NodePath = ^"HUD"
@export var camera_path: NodePath = ^"Camera2D"
@export var link_line_path: NodePath = ^"ElasticLink"
@export var finish_line_path: NodePath = ^"Level/FinishLine"

@export var level_length := 4300.0
@export var level_height := 900.0
@export var finish_line_margin := 0.0
@export var camera_scroll_speed := 0
@export var camera_follow_ahead := 220.0
@export var camera_follow_lerp_speed := 8.0
@export var camera_view_size := Vector2(1280.0, 720.0)
@export var camera_player_margin := 58.0
@export var comfortable_link_length := 360.0
@export var maximum_link_length := 420.0
@export var taut_solo_mover_scale := 0.42
@export var taut_solo_follower_speed_share := 0.82
@export var outward_velocity_damping := 1.0
@export var spring_return_strength := 7.5
@export var max_constraint_push_share := 0.5
@export var body_drag_resistance_start := 140.0
@export var body_drag_resistance_full := 330.0
@export var body_drag_min_away_speed_scale := 0.05
@export var body_drag_max_player_distance := 340.0
@export var body_drag_recoil_start := 190.0
@export var body_drag_recoil_strength := 18.0

@onready var player_one = get_node(player_one_path)
@onready var player_two = get_node(player_two_path)
@onready var body_core = get_node(body_core_path)
@onready var hud = get_node(hud_path)
@onready var camera = get_node(camera_path)
@onready var link_line = get_node(link_line_path)
@onready var finish_line = get_node_or_null(finish_line_path)

var decks_by_player := {}
var game_has_ended := false
var reward_choice_active := false
var card_effect_runner


func _ready() -> void:
	camera.make_current()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_default_input_actions()
	hud.initialize(camera)
	_sync_level_length_from_scene()
	card_effect_runner = CardEffectRunnerScript.new()
	card_effect_runner.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(card_effect_runner)
	card_effect_runner.setup(self)
	_build_initial_decks()
	_connect_task_points()
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	hud.card_reward_selected.connect(_finish_reward_choice)
	body_core.health_changed.connect(_on_body_health_changed)
	body_core.link_broken_started.connect(_on_link_broken_started)
	body_core.link_restored.connect(_on_link_restored)
	body_core.game_over_requested.connect(_on_game_over_requested)
	_update_body_and_line(0.0, false, true)
	_advance_camera(0.0, true)
	_update_hud()


func _physics_process(delta: float) -> void:
	if game_has_ended:
		return
	if get_tree().paused:
		_update_hud()
		return
	if reward_choice_active:
		_update_hud()
		return

	for deck in decks_by_player.values():
		deck.tick(delta)

	_handle_card_input()
	_move_players(delta)
	_advance_camera(delta)
	_clamp_players_to_camera()
	_update_body_and_line(delta)
	_separate_players_from_body()
	_update_body_and_line(0.0, false)
	_check_finish_condition()
	_update_hud()


func _ensure_default_input_actions() -> void:
	_register_key_action("p1_move_left", KEY_A)
	_register_key_action("p1_move_right", KEY_D)
	_register_key_action("p1_move_up", KEY_W)
	_register_key_action("p1_move_down", KEY_S)
	_register_key_action("p2_move_left", KEY_LEFT)
	_register_key_action("p2_move_right", KEY_RIGHT)
	_register_key_action("p2_move_up", KEY_UP)
	_register_key_action("p2_move_down", KEY_DOWN)
	_register_key_action(ACTION_P1_PLAY_CARD, KEY_Q)
	_register_key_action(ACTION_P1_PASS_CARD, KEY_E)
	_register_key_action(ACTION_P2_PLAY_CARD, KEY_K)
	_register_key_action(ACTION_P2_PASS_CARD, KEY_L)


func _register_key_action(action_name: StringName, physical_keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)

	for existing_event in InputMap.action_get_events(action_name):
		if existing_event is InputEventKey and existing_event.physical_keycode == physical_keycode:
			return

	var key_event := InputEventKey.new()
	key_event.physical_keycode = physical_keycode
	InputMap.action_add_event(action_name, key_event)


func _build_initial_decks() -> void:
	var player_one_deck = CardDeckScript.new()
	player_one_deck.setup(1, CardCatalogScript.make_initial_deck(1))

	var player_two_deck = CardDeckScript.new()
	player_two_deck.setup(2, CardCatalogScript.make_initial_deck(2))

	decks_by_player[1] = player_one_deck
	decks_by_player[2] = player_two_deck


func _connect_task_points() -> void:
	for task_point in get_tree().get_nodes_in_group("task_points"):
		if task_point.has_signal("task_point_claimed"):
			task_point.task_point_claimed.connect(_on_task_point_claimed)


func _sync_level_length_from_scene() -> void:
	var inferred_length := level_length
	var right_wall := get_node_or_null(^"Level/RightWall")
	if right_wall is Node2D:
		inferred_length = maxf(inferred_length, right_wall.global_position.x)

	var finish_x := _get_finish_x()
	if is_finite(finish_x):
		inferred_length = maxf(inferred_length, finish_x + camera_player_margin)

	level_length = inferred_length
	camera.limit_right = roundi(level_length)


func _get_finish_x() -> float:
	if not is_instance_valid(finish_line):
		return level_length

	if finish_line is Polygon2D:
		var finish_polygon: PackedVector2Array = finish_line.polygon
		if finish_polygon.is_empty():
			return finish_line.global_position.x

		var maximum_x := -INF
		for point in finish_polygon:
			var world_point: Vector2 = finish_line.to_global(point)
			maximum_x = maxf(maximum_x, world_point.x)
		return maximum_x + finish_line_margin

	if finish_line is Node2D:
		return finish_line.global_position.x + finish_line_margin

	return level_length


func _handle_card_input() -> void:
	if Input.is_action_just_pressed(ACTION_P1_PLAY_CARD):
		_play_card_for_player(1)
	if Input.is_action_just_pressed(ACTION_P1_PASS_CARD):
		_pass_card_for_player(1)
	if Input.is_action_just_pressed(ACTION_P2_PLAY_CARD):
		_play_card_for_player(2)
	if Input.is_action_just_pressed(ACTION_P2_PASS_CARD):
		_pass_card_for_player(2)


func _play_card_for_player(player_id: int) -> void:
	var deck = decks_by_player[player_id]
	var current_card: Dictionary = deck.peek_current_card()
	if current_card.is_empty():
		return
	if not card_effect_runner.can_player_play(player_id):
		hud.set_message("P%d 暂时无法出牌" % player_id)
		return
	if not card_effect_runner.is_card_playable(current_card):
		hud.set_message("P%d 当前不能打出 %s" % [player_id, current_card.get("name", "未命名牌")])
		return

	var cooldown_seconds: float = card_effect_runner.get_play_cooldown(player_id, current_card)
	var played_card: Dictionary = deck.play_current_card(body_core.is_link_active(), cooldown_seconds)
	if played_card.is_empty():
		return

	card_effect_runner.on_card_success_started(player_id, played_card)
	card_effect_runner.apply_card(player_id, played_card)
	hud.set_message("P%d 打出 %s" % [player_id, played_card.get("name", "未命名牌")])


func _pass_card_for_player(player_id: int) -> void:
	var deck = decks_by_player[player_id]
	var current_card: Dictionary = deck.peek_current_card()
	if current_card.is_empty():
		return

	var cooldown_seconds: float = card_effect_runner.get_pass_cooldown(player_id, current_card)
	var passed_card: Dictionary = deck.pass_current_card(cooldown_seconds)
	if passed_card.is_empty():
		return

	card_effect_runner.on_card_passed(player_id, passed_card)
	hud.set_message("P%d 跳过 %s，放到牌堆底部" % [player_id, passed_card.get("name", "未命名牌")])


func _advance_camera(delta: float, snap_to_target := false) -> void:
	var target_position: Vector2 = _get_camera_target_position(delta)
	if snap_to_target:
		camera.global_position = Vector2(target_position.x, 0.0)
		return

	var follow_weight: float = clampf(delta * camera_follow_lerp_speed, 0.0, 1.0)
	var next_x: float = lerpf(camera.global_position.x, target_position.x, follow_weight)
	camera.global_position = Vector2(next_x, 0.0)


func _get_camera_target_position(delta: float) -> Vector2:
	var half_width: float = camera_view_size.x * 0.5
	var half_height: float = camera_view_size.y * 0.5
	var party_center: Vector2 = (player_one.global_position + player_two.global_position) * 0.5
	var minimum_scroll_x: float = camera.global_position.x + camera_scroll_speed * delta
	var followed_x: float = party_center.x + camera_follow_ahead
	var target_x: float = maxf(minimum_scroll_x, followed_x)
	var target_y := 0.0
	var minimum_camera_x: float = half_width
	var maximum_camera_x: float = level_length - half_width
	var minimum_camera_y: float = -level_height * 0.5 + half_height
	var maximum_camera_y: float = level_height * 0.5 - half_height
	return Vector2(
		clampf(target_x, minimum_camera_x, maximum_camera_x),
		clampf(target_y, minimum_camera_y, maximum_camera_y)
	)


func _move_players(delta: float) -> void:
	var input_one: Vector2 = player_one.read_input_vector()
	var input_two: Vector2 = player_two.read_input_vector()

	if body_core.is_link_active():
		var body_drag_ratio: float = _get_body_drag_ratio()
		var linked_velocities: Array = _calculate_linked_velocities(input_one, input_two)
		linked_velocities[0] = _apply_body_drag_resistance(linked_velocities[0], player_one.global_position, body_drag_ratio)
		linked_velocities[1] = _apply_body_drag_resistance(linked_velocities[1], player_two.global_position, body_drag_ratio)
		player_one.move_with_velocity(linked_velocities[0])
		player_two.move_with_velocity(linked_velocities[1])
		_apply_max_link_constraint()
		_apply_link_spring_recoil(delta, input_one, input_two)
		_apply_body_drag_distance_constraint(delta, input_one, input_two)
	else:
		player_one.move_with_velocity(input_one * _get_player_move_speed(player_one))
		player_two.move_with_velocity(input_two * _get_player_move_speed(player_two))


func _calculate_linked_velocities(input_one: Vector2, input_two: Vector2) -> Array:
	var player_one_speed := _get_player_move_speed(player_one)
	var player_two_speed := _get_player_move_speed(player_two)
	var velocity_one: Vector2 = input_one * player_one_speed
	var velocity_two: Vector2 = input_two * player_two_speed

	var separation: Vector2 = player_two.global_position - player_one.global_position
	var distance: float = separation.length()
	if distance <= 0.0:
		return [velocity_one, velocity_two]

	var direction: Vector2 = separation / distance
	var relative_velocity: Vector2 = velocity_two - velocity_one
	var outward_speed: float = relative_velocity.dot(direction)
	if _inputs_are_shared_direction(input_one, input_two) and outward_speed <= 0.0:
		return [velocity_one, velocity_two]

	var tension_ratio: float = _get_tension_ratio(distance)
	if tension_ratio <= 0.0:
		return [velocity_one, velocity_two]

	if outward_speed > 0.0:
		var outward_resistance: float = tension_ratio * outward_velocity_damping
		if _inputs_are_opposing(input_one, input_two):
			outward_resistance = maxf(outward_resistance, tension_ratio)
		outward_resistance = clampf(outward_resistance, 0.0, 1.0)
		var damped_outward_speed: float = outward_speed * (1.0 - outward_resistance)
		var outward_velocity_delta: Vector2 = direction * (outward_speed - damped_outward_speed)
		velocity_one += outward_velocity_delta * 0.5
		velocity_two -= outward_velocity_delta * 0.5

	var one_is_moving: bool = input_one.length() > 0.0
	var two_is_moving: bool = input_two.length() > 0.0
	if one_is_moving and not two_is_moving:
		var pull_speed: float = player_one_speed * taut_solo_follower_speed_share * tension_ratio
		velocity_two += -direction * pull_speed
		velocity_one *= lerpf(1.0, taut_solo_mover_scale, tension_ratio)
	elif two_is_moving and not one_is_moving:
		var pull_speed: float = player_two_speed * taut_solo_follower_speed_share * tension_ratio
		velocity_one += direction * pull_speed
		velocity_two *= lerpf(1.0, taut_solo_mover_scale, tension_ratio)
	return [velocity_one, velocity_two]


func _get_player_move_speed(player: Node) -> float:
	if player.has_method("get_current_move_speed"):
		return float(player.get_current_move_speed())
	var fallback_speed = player.get("move_speed")
	if fallback_speed == null:
		return 0.0
	return float(fallback_speed)


func _get_body_drag_ratio() -> float:
	if not body_core.is_link_active():
		return 0.0

	var body_drag_distance: float = _get_body_drag_distance()
	return clampf(
		inverse_lerp(body_drag_resistance_start, body_drag_resistance_full, body_drag_distance),
		0.0,
		1.0
	)


func _get_body_drag_distance() -> float:
	var link_center: Vector2 = (player_one.global_position + player_two.global_position) * 0.5
	var body_position: Vector2 = body_core.global_position
	var center_lag: float = body_position.distance_to(link_center)
	var average_player_distance: float = (
		body_position.distance_to(player_one.global_position)
		+ body_position.distance_to(player_two.global_position)
	) * 0.5
	return maxf(center_lag, average_player_distance - comfortable_link_length * 0.25)


func _apply_body_drag_resistance(velocity: Vector2, player_position: Vector2, drag_ratio: float) -> Vector2:
	if drag_ratio <= 0.0 or velocity.length() <= 0.001:
		return velocity

	var away_from_body: Vector2 = player_position - body_core.global_position
	if away_from_body.length() <= 0.001:
		return velocity

	var away_direction: Vector2 = away_from_body.normalized()
	var away_speed: float = velocity.dot(away_direction)
	if away_speed <= 0.0:
		return velocity

	var resisted_away_speed: float = away_speed * lerpf(1.0, body_drag_min_away_speed_scale, drag_ratio)
	return velocity - away_direction * (away_speed - resisted_away_speed)


func _apply_body_drag_distance_constraint(delta: float, input_one: Vector2, input_two: Vector2) -> void:
	if not body_core.is_link_active():
		return

	_apply_single_player_body_drag_constraint(player_one, input_one, delta)
	_apply_single_player_body_drag_constraint(player_two, input_two, delta)


func _apply_single_player_body_drag_constraint(player: Node, input_vector: Vector2, delta: float) -> void:
	var body_to_player: Vector2 = player.global_position - body_core.global_position
	var distance: float = body_to_player.length()
	if distance <= 0.001:
		return

	var away_direction: Vector2 = body_to_player / distance
	if distance > body_drag_max_player_distance:
		var hard_correction: Vector2 = -away_direction * (distance - body_drag_max_player_distance)
		_move_player_by_tether(player, hard_correction)
		distance = body_drag_max_player_distance

	if delta <= 0.0 or distance <= body_drag_recoil_start:
		return

	var still_pulling_away: bool = input_vector.length() > 0.0 and input_vector.dot(away_direction) > 0.15
	if still_pulling_away:
		return

	var recoil_distance: float = distance - body_drag_recoil_start
	var recoil_amount: float = minf(recoil_distance, recoil_distance * body_drag_recoil_strength * delta)
	_move_player_by_tether(player, -away_direction * recoil_amount)


func _apply_max_link_constraint() -> void:
	for _iteration in range(5):
		var separation: Vector2 = player_two.global_position - player_one.global_position
		var distance: float = separation.length()
		if distance <= maximum_link_length + 0.1 or distance <= 0.0:
			break

		var direction: Vector2 = separation / distance
		var overflow: float = distance - maximum_link_length
		var push_share: float = clampf(max_constraint_push_share, 0.0, 1.0)
		var player_one_before: Vector2 = player_one.global_position
		var player_two_before: Vector2 = player_two.global_position
		_move_player_by_tether(player_one, direction * overflow * push_share)
		_move_player_by_tether(player_two, -direction * overflow * (1.0 - push_share))

		var player_one_progress: float = maxf(0.0, (player_one.global_position - player_one_before).dot(direction))
		var player_two_progress: float = maxf(0.0, (player_two_before - player_two.global_position).dot(direction))
		var remaining_overflow: float = overflow - player_one_progress - player_two_progress
		if remaining_overflow <= 0.1:
			break

		if player_one_progress < overflow * push_share * 0.5 and player_two_progress > 0.1:
			_move_player_by_tether(player_two, -direction * remaining_overflow)
		elif player_two_progress < overflow * (1.0 - push_share) * 0.5 and player_one_progress > 0.1:
			_move_player_by_tether(player_one, direction * remaining_overflow)
		else:
			_move_player_by_tether(player_one, direction * remaining_overflow * 0.5)
			_move_player_by_tether(player_two, -direction * remaining_overflow * 0.5)

	player_one.velocity = Vector2.ZERO
	player_two.velocity = Vector2.ZERO


func _apply_link_spring_recoil(delta: float, input_one: Vector2, input_two: Vector2) -> void:
	var separation: Vector2 = player_two.global_position - player_one.global_position
	var distance: float = separation.length()
	if distance <= comfortable_link_length or distance <= 0.0:
		return

	var direction: Vector2 = separation / distance
	var relative_input: Vector2 = input_two - input_one
	var still_pulling_apart: bool = relative_input.dot(direction) > 0.15
	if still_pulling_apart:
		return

	var tension_ratio: float = _get_tension_ratio(distance)
	var correction_amount: float = minf(
		distance - comfortable_link_length,
		(distance - comfortable_link_length) * spring_return_strength * delta * (0.25 + tension_ratio * 0.75)
	)
	var correction: Vector2 = direction * correction_amount * 0.5
	_move_player_by_tether(player_one, correction)
	_move_player_by_tether(player_two, -correction)


func _move_player_by_tether(player: Node, motion: Vector2) -> void:
	if motion.length() <= 0.001:
		return
	if player.has_method("apply_tether_motion"):
		player.apply_tether_motion(motion)
	else:
		player.global_position += motion


func _get_tension_ratio(distance: float) -> float:
	if distance <= comfortable_link_length:
		return 0.0
	if maximum_link_length <= comfortable_link_length:
		return 1.0
	return inverse_lerp(comfortable_link_length, maximum_link_length, minf(distance, maximum_link_length))


func _inputs_are_opposing(input_one: Vector2, input_two: Vector2) -> bool:
	if input_one.length() <= 0.0 or input_two.length() <= 0.0:
		return false
	return input_one.dot(input_two) <= OPPOSING_INPUT_DOT


func _inputs_are_shared_direction(input_one: Vector2, input_two: Vector2) -> bool:
	if input_one.length() <= 0.0 or input_two.length() <= 0.0:
		return false
	return input_one.dot(input_two) >= SHARED_INPUT_DOT


func _clamp_players_to_camera() -> void:
	var half_size: Vector2 = camera_view_size * 0.5
	var visible_left: float = maxf(camera_player_margin, camera.global_position.x - half_size.x + camera_player_margin)
	var visible_right: float = minf(level_length - camera_player_margin, camera.global_position.x + half_size.x - camera_player_margin)
	var visible_top: float = -level_height * 0.5 + camera_player_margin
	var visible_bottom: float = level_height * 0.5 - camera_player_margin

	for player in [player_one, player_two]:
		player.global_position.x = clampf(player.global_position.x, visible_left, visible_right)
		player.global_position.y = clampf(player.global_position.y, visible_top, visible_bottom)


func _separate_players_from_body() -> void:
	var player_minimum_distance: float = 52.0
	var body_minimum_distance: float = 48.0
	var player_separation: Vector2 = player_two.global_position - player_one.global_position
	if player_separation.length() > 0.0 and player_separation.length() < player_minimum_distance:
		var correction: Vector2 = player_separation.normalized() * (player_minimum_distance - player_separation.length()) * 0.5
		player_one.global_position -= correction
		player_two.global_position += correction

	for player in [player_one, player_two]:
		var body_offset: Vector2 = player.global_position - body_core.global_position
		if body_offset.length() > 0.0 and body_offset.length() < body_minimum_distance:
			player.global_position += body_offset.normalized() * (body_minimum_distance - body_offset.length())


func _update_body_and_line(delta := 0.0, apply_net_strain := true, snap_to_center := false) -> void:
	var body_target: Vector2 = (player_one.global_position + player_two.global_position) * 0.5
	if snap_to_center or not body_core.is_link_active():
		body_core.place_between(player_one.global_position, player_two.global_position)
	elif body_core.is_snapback_active():
		var blocker = body_core.advance_snapback_to_position(body_target, delta)
		if apply_net_strain:
			_apply_net_strain(blocker, body_target, delta)
	else:
		var blocker = body_core.move_toward_position(body_target)
		if apply_net_strain:
			_apply_net_strain(blocker, body_target, delta)

	if body_core.is_link_active():
		link_line.visible = true
		link_line.points = PackedVector2Array([
			player_one.global_position,
			body_core.global_position,
			player_two.global_position,
		])
	else:
		link_line.visible = false


func _apply_net_strain(blocker: Node, body_target: Vector2, delta: float) -> void:
	if blocker == null or delta <= 0.0 or not blocker.has_method("apply_tether_strain"):
		return

	var lag_distance: float = body_core.global_position.distance_to(body_target)
	var released_now: bool = blocker.apply_tether_strain(lag_distance, delta)
	if released_now:
		body_core.start_snapback()
		hud.set_message("肉体挣脱网，回弹到连线中心")


func _update_hud() -> void:
	hud.set_health(body_core.current_health, body_core.max_health)
	hud.set_link_state(body_core.is_link_active(), body_core.broken_seconds_left)
	for player_id in decks_by_player.keys():
		var deck = decks_by_player[player_id]
		hud.set_player_deck_status(player_id, deck.current_card_name(), deck.card_count(), deck.cooldown_remaining)


func _check_finish_condition() -> void:
	var finish_x: float = _get_finish_x()
	if minf(player_one.global_position.x, player_two.global_position.x) >= finish_x:
		_end_game("抵达终点")


func _end_game(message: String) -> void:
	if game_has_ended:
		return

	game_has_ended = true
	get_tree().paused = false
	player_one.set_control_enabled(false)
	player_two.set_control_enabled(false)
	hud.set_game_result(message)


func _start_reward_choice(player_id: int, reward_cards: Array) -> void:
	if reward_cards.is_empty() or not decks_by_player.has(player_id):
		return

	reward_choice_active = true
	player_one.set_control_enabled(false)
	player_two.set_control_enabled(false)
	hud.show_reward_choice(player_id, reward_cards)
	hud.set_message("P%d 抵达专属任务点，选择 1 张奖励牌" % player_id)
	get_tree().paused = true


func _finish_reward_choice(player_id: int, selected_card: Dictionary) -> void:
	if not reward_choice_active or selected_card.is_empty() or not decks_by_player.has(player_id):
		return

	decks_by_player[player_id].add_card(selected_card)
	hud.hide_reward_choice()
	hud.set_message("P%d 获得 %s" % [player_id, selected_card.get("name", "未命名牌")])
	reward_choice_active = false
	get_tree().paused = false
	if not game_has_ended:
		player_one.set_control_enabled(true)
		player_two.set_control_enabled(true)
	_update_hud()


func _on_body_health_changed(current_health: float, max_health: float) -> void:
	hud.set_health(current_health, max_health)


func _on_link_broken_started(seconds_left: float) -> void:
	hud.set_link_state(false, seconds_left)


func _on_link_restored() -> void:
	hud.set_link_state(true, 0.0)
	hud.set_message("连线已恢复")


func _on_game_over_requested() -> void:
	_end_game("断线结束")


func _on_task_point_claimed(_point: Node, player_id: int, reward_cards: Array) -> void:
	var final_reward_cards := reward_cards
	if final_reward_cards.is_empty():
		final_reward_cards = CardCatalogScript.make_reward_choices(player_id)
	_start_reward_choice(player_id, final_reward_cards)
