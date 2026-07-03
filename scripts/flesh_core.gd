class_name FleshCore
extends AnimatableBody3D

## damage_received is emitted whenever the flesh core successfully takes damage so
## UI and game state can update from the same authoritative health change.
signal damage_received(amount: float, remaining_health: float)

## depleted is emitted exactly when health reaches zero and the link should break.
signal depleted

## restored is emitted when the link is restored and health is filled back to max.
signal restored

## max_health is the full flesh health value shown prominently in the HUD and
## restored whenever the shared restore-link card succeeds.
@export var max_health: float = 100.0

## collision_shape_path points to the solid body volume that prevents both players
## from overlapping the flesh core.
@export var collision_shape_path: NodePath = NodePath("CollisionShape3D")

## visual_path points to the editable mesh that represents the flesh core in the
## scene and is hidden when the link is disconnected.
@export var visual_path: NodePath = NodePath("Visual")

## current_health stores the live health value after enemy contact or future attack
## systems damage the flesh core.
var current_health: float = 100.0

## is_link_active records whether the core currently exists as the center hit point
## of the player link.
var is_link_active: bool = true

## collision_shape caches the exported collision node for fast enable/disable calls.
@onready var collision_shape: CollisionShape3D = get_node(collision_shape_path) as CollisionShape3D

## visual caches the editable visible mesh so script logic can hide it without
## replacing artist-editable scene content.
@onready var visual: Node3D = get_node(visual_path) as Node3D


## _ready initializes the flesh core to full health and keeps the scene's editable
## collision and visual children synchronized with the active link state.
func _ready() -> void:
	reset_health()
	set_link_active(true)


## reset_health refills the flesh core to max health without changing whether the
## link is currently active.
func reset_health() -> void:
	current_health = max_health


## take_damage reduces health only while the link is active, emits detailed damage
## information, and announces depletion when health reaches zero.
func take_damage(amount: float) -> void:
	if not is_link_active:
		return

	current_health = maxf(current_health - amount, 0.0)
	damage_received.emit(amount, current_health)
	if current_health <= 0.0:
		depleted.emit()


## restore_link_state marks the flesh core active again, refills health, restores
## collision, restores visuals, and emits a signal for UI/status feedback.
func restore_link_state() -> void:
	reset_health()
	set_link_active(true)
	restored.emit()


## set_link_active enables or disables the physical and visible flesh core when the
## connection exists or has been broken by zero health.
func set_link_active(active: bool) -> void:
	is_link_active = active
	if is_instance_valid(collision_shape):
		collision_shape.disabled = not active
	if is_instance_valid(visual):
		visual.visible = active


## set_core_position moves the solid hit point to the current midpoint of the two
## connected players so attacks and player collision stay centered on the rope.
func set_core_position(new_position: Vector3) -> void:
	global_position = new_position


## get_health_ratio returns a 0-to-1 value for progress bars and warning effects.
func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return clampf(current_health / max_health, 0.0, 1.0)
