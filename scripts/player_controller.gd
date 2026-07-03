class_name PlayerController
extends CharacterBody3D

## player_id identifies this controllable character for task-point ownership,
## card ownership, UI labels, and any future player-specific collision logic.
@export var player_id: int = 1

## move_speed is the maximum manual steering speed on the X/Z gameplay plane before
## the shared link controller adds automatic rightward movement and elastic forces.
@export var move_speed: float = 7.0

## move_left_action is the InputMap action read when this player wants to move left.
@export var move_left_action: StringName = &"p1_move_left"

## move_right_action is the InputMap action read when this player wants to move right.
@export var move_right_action: StringName = &"p1_move_right"

## move_up_action is the InputMap action read when this player wants to move toward
## the upper side of the rectangular route.
@export var move_up_action: StringName = &"p1_move_up"

## move_down_action is the InputMap action read when this player wants to move toward
## the lower side of the rectangular route.
@export var move_down_action: StringName = &"p1_move_down"

## play_card_action is the InputMap action that attempts to play the current top card.
@export var play_card_action: StringName = &"p1_play_card"

## skip_card_action is the InputMap action that rotates the current top card away
## without playing it.
@export var skip_card_action: StringName = &"p1_skip_card"

## last_requested_direction stores the most recent normalized input direction so
## animation, debugging, or future UI can inspect what this player intended to do.
var last_requested_direction: Vector3 = Vector3.ZERO

## last_applied_velocity stores the final velocity after camera drift and link
## forces so tuning can compare intent against actual movement.
var last_applied_velocity: Vector3 = Vector3.ZERO


## _ready configures the CharacterBody3D as a top-down floating body so the players
## move on the X/Z plane and are not treated as gravity-driven platform characters.
func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	floor_snap_length = 0.0


## get_player_id returns the exported ownership id in a method form so Area3D task
## points can safely identify player bodies without reaching into variables.
func get_player_id() -> int:
	return player_id


## get_movement_input converts the four configured InputMap actions into a normalized
## world-space X/Z direction where X is level progress and Z is lane movement.
func get_movement_input() -> Vector3:
	var input_vector: Vector2 = Input.get_vector(move_left_action, move_right_action, move_up_action, move_down_action)
	last_requested_direction = Vector3(input_vector.x, 0.0, input_vector.y).limit_length(1.0)
	return last_requested_direction


## get_requested_velocity returns this player's manual velocity before shared
## automatic scrolling and rope forces are applied by the main controller.
func get_requested_velocity() -> Vector3:
	return get_movement_input() * move_speed


## move_with_world_velocity applies a final world-space velocity chosen by the main
## controller, then lets Godot resolve collisions with players, flesh, walls,
## obstacles, and player-only camera blockers.
func move_with_world_velocity(world_velocity: Vector3) -> void:
	last_applied_velocity = world_velocity
	velocity = world_velocity
	move_and_slide()
