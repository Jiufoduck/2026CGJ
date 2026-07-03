class_name MainController
extends Node3D

## CardDeckScript preloads the deck logic directly so the main controller works even
## before Godot has built its global class-name cache for a fresh project checkout.
const CardDeckScript: Script = preload("res://scripts/card_deck.gd")

## DEFAULT_INPUT_KEYS maps runtime InputMap actions to default keyboard keys so the
## playable prototype works even before the project input settings are hand-edited.
const DEFAULT_INPUT_KEYS: Dictionary = {
	&"p1_move_left": KEY_A,
	&"p1_move_right": KEY_D,
	&"p1_move_up": KEY_W,
	&"p1_move_down": KEY_S,
	&"p1_play_card": KEY_F,
	&"p1_skip_card": KEY_G,
	&"p2_move_left": KEY_LEFT,
	&"p2_move_right": KEY_RIGHT,
	&"p2_move_up": KEY_UP,
	&"p2_move_down": KEY_DOWN,
	&"p2_play_card": KEY_K,
	&"p2_skip_card": KEY_L,
}

## STATUS_READY is the initial HUD message that reminds testers of the two-player
## control layout without moving any UI construction into script.
const STATUS_READY: String = "WASD/F/G 控制玩家一，方向键/K/L 控制玩家二。"

## CARD_KIND_ATTACK mirrors CardDeck.CardKind.ATTACK for lightweight card effect
## checks without requiring a global class-name lookup during first import.
const CARD_KIND_ATTACK: int = 0

## RESTORE_CARD_ID mirrors the deck's shared restore card id so restore behavior can
## be recognized from the card dictionary without global class-name lookup.
const RESTORE_CARD_ID: StringName = &"restore_link"

## player_one_path points to the first editable Player scene instance.
@export var player_one_path: NodePath = NodePath("Players/PlayerOne")

## player_two_path points to the second editable Player scene instance.
@export var player_two_path: NodePath = NodePath("Players/PlayerTwo")

## flesh_core_path points to the editable center hit-point scene instance.
@export var flesh_core_path: NodePath = NodePath("FleshCore")

## link_visual_path points to the editable mesh used to draw the elastic line.
@export var link_visual_path: NodePath = NodePath("LinkVisual")

## hud_path points to the editable CanvasLayer UI scene instance.
@export var hud_path: NodePath = NodePath("GameHUD")

## camera_rig_path points to the rig that moves right and carries player-only camera
## blockers with it.
@export var camera_rig_path: NodePath = NodePath("CameraRig")

## automatic_forward_speed makes both players steadily move right, matching the
## document's "spawn left and always move right" main-route behavior.
@export var automatic_forward_speed: float = 2.4

## camera_speed controls how quickly the camera view scrolls right through the long
## rectangular level.
@export var camera_speed: float = 2.4

## finish_x is the X position at the far right of the route that ends the game.
@export var finish_x: float = 150.0

## link_rest_length is the distance where the elastic connection begins to pull back.
@export var link_rest_length: float = 9.0

## max_link_length is the intended maximum comfortable separation before hard
## resistance makes pulling farther increasingly difficult.
@export var max_link_length: float = 15.0

## link_resistance_strength scales how strongly separating movement is damped after
## the players stretch past link_rest_length.
@export var link_resistance_strength: float = 0.85

## link_spring_strength controls the soft pull that nudges stopped players back
## together after the elastic line is stretched.
@export var link_spring_strength: float = 2.4

## link_hard_pull_strength controls the stronger pull applied when the players exceed
## max_link_length.
@export var link_hard_pull_strength: float = 7.0

## disconnected_game_over_seconds is the required ten second grace period after the
## flesh health reaches zero and the link breaks.
@export var disconnected_game_over_seconds: float = 10.0

## player_one caches the first player for movement, cards, and task ownership.
@onready var player_one = get_node(player_one_path)

## player_two caches the second player for movement, cards, and task ownership.
@onready var player_two = get_node(player_two_path)

## flesh_core caches the link midpoint body that owns health and collision.
@onready var flesh_core = get_node(flesh_core_path)

## link_visual caches the visible elastic connection mesh.
@onready var link_visual: MeshInstance3D = get_node(link_visual_path) as MeshInstance3D

## hud caches the UI scene so gameplay can send it display data only.
@onready var hud = get_node(hud_path)

## camera_rig caches the camera and player-only blockers that scroll right.
@onready var camera_rig: Node3D = get_node(camera_rig_path) as Node3D

## player_one_deck stores player one's independent ordered card pile.
var player_one_deck

## player_two_deck stores player two's independent ordered card pile.
var player_two_deck

## is_link_connected records whether the two players are currently connected by the
## elastic rope and protected by the flesh core.
var is_link_connected: bool = true

## disconnected_time_remaining counts down the ten second game-over timer after the
## link breaks.
var disconnected_time_remaining: float = 0.0

## game_finished prevents movement, repeated win/loss messages, and repeated card
## input once the scene has reached an end condition.
var game_finished: bool = false


## _ready wires together editable scene instances, initializes decks, connects
## task-point and flesh-core signals, and publishes the starting HUD state.
func _ready() -> void:
	_ensure_default_inputs()
	player_one_deck = CardDeckScript.new(1)
	player_two_deck = CardDeckScript.new(2)
	flesh_core.depleted.connect(_on_flesh_core_depleted)
	flesh_core.damage_received.connect(_on_flesh_core_damage_received)
	_connect_task_points()
	_update_link_objects()
	hud.show_status(STATUS_READY)
	_refresh_hud()


## _physics_process advances the active game systems in a stable order: cooldowns,
## input cards, scrolling, movement, connection timers, link visuals, finish checks,
## and UI refresh.
func _physics_process(delta: float) -> void:
	if game_finished:
		return

	player_one_deck.update_cooldown(delta)
	player_two_deck.update_cooldown(delta)
	_handle_card_input()
	_advance_camera(delta)
	_apply_player_movement(delta)
	_update_disconnected_timer(delta)
	_update_link_objects()
	_check_finish_line()
	_refresh_hud()


## _ensure_default_inputs creates missing InputMap actions and assigns the default
## keys used by the editable player scene instances.
func _ensure_default_inputs() -> void:
	for action_name: StringName in DEFAULT_INPUT_KEYS.keys():
		_ensure_action_with_key(action_name, int(DEFAULT_INPUT_KEYS[action_name]))


## _ensure_action_with_key adds one physical key event to an action only if that key
## is not already present, preserving any manual InputMap edits made in the editor.
func _ensure_action_with_key(action_name: StringName, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for input_event: InputEvent in InputMap.action_get_events(action_name):
		if input_event is InputEventKey and (input_event as InputEventKey).physical_keycode == keycode:
			return

	var key_event: InputEventKey = InputEventKey.new()
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action_name, key_event)


## _connect_task_points discovers every TaskPoint scene that registered itself and
## connects collection to the card reward system.
func _connect_task_points() -> void:
	for task_node: Node in get_tree().get_nodes_in_group("task_points"):
		if task_node.has_signal("task_point_collected"):
			var callback: Callable = Callable(self, "_on_task_point_collected")
			if not task_node.is_connected("task_point_collected", callback):
				task_node.connect("task_point_collected", callback)


## _advance_camera scrolls the camera rig right until the route's finish area so
## players are continually pushed through the long rectangular scene.
func _advance_camera(delta: float) -> void:
	camera_rig.global_position.x = minf(camera_rig.global_position.x + camera_speed * delta, finish_x)


## _apply_player_movement combines player input, automatic rightward travel, and
## elastic-link resistance before moving both CharacterBody3D players.
func _apply_player_movement(delta: float) -> void:
	var velocity_one: Vector3 = player_one.get_requested_velocity() + Vector3.RIGHT * automatic_forward_speed
	var velocity_two: Vector3 = player_two.get_requested_velocity() + Vector3.RIGHT * automatic_forward_speed

	if is_link_connected:
		var constrained_velocities: Array[Vector3] = _apply_link_constraint(velocity_one, velocity_two, delta)
		velocity_one = constrained_velocities[0]
		velocity_two = constrained_velocities[1]

	player_one.move_with_world_velocity(velocity_one)
	player_two.move_with_world_velocity(velocity_two)


## _apply_link_constraint returns modified velocities that make opposite pulling
## resist, shared movement remain free, one-player pulling feel heavy, and stretched
## stopped players spring slightly back toward each other.
func _apply_link_constraint(velocity_one: Vector3, velocity_two: Vector3, _delta: float) -> Array[Vector3]:
	var first_to_second: Vector3 = player_two.global_position - player_one.global_position
	first_to_second.y = 0.0
	var distance: float = first_to_second.length()
	if distance <= 0.001:
		return [velocity_one, velocity_two]

	var link_direction: Vector3 = first_to_second / distance
	var adjusted_one: Vector3 = velocity_one
	var adjusted_two: Vector3 = velocity_two
	var stretch_beyond_rest: float = maxf(distance - link_rest_length, 0.0)
	var stretch_window: float = maxf(max_link_length - link_rest_length, 0.001)
	var stretch_ratio: float = clampf(stretch_beyond_rest / stretch_window, 0.0, 1.0)
	var relative_velocity: Vector3 = adjusted_two - adjusted_one
	var separating_speed: float = relative_velocity.dot(link_direction)

	if separating_speed > 0.0 and stretch_ratio > 0.0:
		var damping: float = separating_speed * link_resistance_strength * stretch_ratio * 0.5
		adjusted_one += link_direction * damping
		adjusted_two -= link_direction * damping

	if stretch_beyond_rest > 0.0:
		var soft_pull_speed: float = stretch_beyond_rest * link_spring_strength * stretch_ratio
		adjusted_one += link_direction * soft_pull_speed
		adjusted_two -= link_direction * soft_pull_speed

	if distance > max_link_length:
		var over_length: float = distance - max_link_length
		var hard_pull_speed: float = over_length * link_hard_pull_strength
		adjusted_one += link_direction * hard_pull_speed
		adjusted_two -= link_direction * hard_pull_speed

	return [adjusted_one, adjusted_two]


## _update_link_objects moves the flesh core to the midpoint and stretches the link
## mesh between players while hiding both when the connection is broken.
func _update_link_objects() -> void:
	if not is_link_connected:
		link_visual.visible = false
		flesh_core.set_link_active(false)
		return

	var midpoint: Vector3 = (player_one.global_position + player_two.global_position) * 0.5
	var second_position: Vector3 = player_two.global_position
	midpoint.y = 0.8
	second_position.y = 0.8
	flesh_core.set_core_position(midpoint)
	flesh_core.set_link_active(true)

	var link_vector: Vector3 = second_position - player_one.global_position
	link_vector.y = 0.0
	link_visual.visible = true
	link_visual.global_position = midpoint
	link_visual.scale = Vector3(0.12, 0.12, maxf(link_vector.length(), 0.01))
	link_visual.look_at(second_position, Vector3.UP)


## _update_disconnected_timer counts down the mandatory ten seconds after link break
## and ends the game if no restore card reconnects the players in time.
func _update_disconnected_timer(delta: float) -> void:
	if is_link_connected:
		return

	disconnected_time_remaining = maxf(disconnected_time_remaining - delta, 0.0)
	if disconnected_time_remaining <= 0.0:
		_finish_game("连线断开超过 10 秒，游戏结束。")


## _handle_card_input reads both players' play/skip actions and routes successful
## card plays to the effect resolver.
func _handle_card_input() -> void:
	if Input.is_action_just_pressed(player_one.play_card_action):
		_try_play_card(player_one, player_one_deck)
	if Input.is_action_just_pressed(player_two.play_card_action):
		_try_play_card(player_two, player_two_deck)
	if Input.is_action_just_pressed(player_one.skip_card_action):
		_skip_card(player_one, player_one_deck)
	if Input.is_action_just_pressed(player_two.skip_card_action):
		_skip_card(player_two, player_two_deck)


## _try_play_card asks a deck to apply its pile rule, then resolves the gameplay
## result only when the card actually played.
func _try_play_card(player, deck) -> void:
	var play_result: Dictionary = deck.try_play_current_card()
	if not bool(play_result.get("played", false)):
		return

	var played_card: Dictionary = play_result["card"]
	_resolve_card_effect(player, played_card)


## _skip_card rotates a player's visible top card away and reports the skipped card
## in the status UI.
func _skip_card(player, deck) -> void:
	var skip_result: Dictionary = deck.skip_current_card()
	if bool(skip_result.get("skipped", false)):
		var skipped_card: Dictionary = skip_result["card"]
		hud.show_status("玩家%d 跳过：%s" % [player.player_id, skipped_card["display_name"]])


## _resolve_card_effect applies attack targeting, restore-link behavior, or a status
## message for placeholder other cards whose final details will be designed later.
func _resolve_card_effect(player, card: Dictionary) -> void:
	if StringName(card.get("id", &"")) == RESTORE_CARD_ID:
		if not is_link_connected:
			_restore_link()
			hud.show_status("玩家%d 打出恢复连线，肉体血量已回满。" % player.player_id)
		else:
			hud.show_status("玩家%d 打出恢复连线，但连线当前完好。" % player.player_id)
		return

	if int(card["kind"]) == CARD_KIND_ATTACK:
		var target_enemy = _find_nearest_enemy(player.global_position, float(card["range"]))
		if target_enemy != null:
			target_enemy.take_damage(float(card["damage"]))
			hud.show_status("玩家%d 打出%s，造成 %.0f 伤害。" % [player.player_id, card["display_name"], card["damage"]])
		else:
			hud.show_status("玩家%d 打出%s，但范围内没有敌人。" % [player.player_id, card["display_name"]])
		return

	hud.show_status("玩家%d 打出%s，其他牌已消耗。" % [player.player_id, card["display_name"]])


## _find_nearest_enemy returns the closest living enemy within a card's range so
## attack cards have a deterministic prototype target.
func _find_nearest_enemy(origin: Vector3, attack_range: float):
	var best_enemy = null
	var best_distance: float = attack_range
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not node.has_method("is_alive") or not node.has_method("take_damage"):
			continue

		if not node.call("is_alive"):
			continue

		var enemy_distance: float = origin.distance_to(node.global_position)
		if enemy_distance <= best_distance:
			best_distance = enemy_distance
			best_enemy = node

	return best_enemy


## _on_task_point_collected gives the appropriate player's deck a restore card and
## reports whether the point was useful or duplicate.
func _on_task_point_collected(task_point, collecting_player_id: int) -> void:
	if not task_point.grants_restore_card:
		hud.show_status("玩家%d 完成任务点。" % collecting_player_id)
		return

	var target_deck = player_one_deck if collecting_player_id == 1 else player_two_deck
	var added: bool = target_deck.add_restore_card_if_missing()
	if added:
		hud.show_status("玩家%d 获得恢复连线牌。" % collecting_player_id)
	else:
		hud.show_status("玩家%d 已经持有恢复连线牌。" % collecting_player_id)


## _on_flesh_core_damage_received updates the HUD immediately after the center hit
## point takes damage.
func _on_flesh_core_damage_received(_amount: float, _remaining_health: float) -> void:
	_refresh_hud()


## _on_flesh_core_depleted breaks the link and starts the ten second loss countdown.
func _on_flesh_core_depleted() -> void:
	if not is_link_connected:
		return

	is_link_connected = false
	disconnected_time_remaining = disconnected_game_over_seconds
	flesh_core.set_link_active(false)
	hud.show_status("肉体血量见底，连线断开！")


## _restore_link reconnects the players, cancels the loss countdown, and refills the
## flesh core health.
func _restore_link() -> void:
	is_link_connected = true
	disconnected_time_remaining = 0.0
	flesh_core.restore_link_state()
	_update_link_objects()


## _check_finish_line ends the game once either player reaches the far right end of
## the long rectangular main scene.
func _check_finish_line() -> void:
	if player_one.global_position.x >= finish_x or player_two.global_position.x >= finish_x:
		_finish_game("抵达最右边，游戏通关。")


## _finish_game locks the scene in a completed state and publishes the final message.
func _finish_game(message: String) -> void:
	game_finished = true
	hud.show_status(message)
	_refresh_hud()


## _refresh_hud pushes health, connection countdown, and current card data to the
## editable UI scene.
func _refresh_hud() -> void:
	hud.update_health(flesh_core.current_health, flesh_core.max_health)
	hud.update_connection_state(is_link_connected, disconnected_time_remaining)
	hud.update_card_panels(player_one_deck, player_two_deck)
