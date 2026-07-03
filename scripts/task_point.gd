class_name TaskPoint
extends Area3D

## task_point_collected tells the main controller that an allowed player picked up
## this point and that its reward should be applied exactly once.
signal task_point_collected(task_point: TaskPoint, player_id: int)

## allowed_player_id is the only player id that may collect this task point, matching
## the document's requirement that every task point belongs to a specific player.
@export var allowed_player_id: int = 1

## grants_restore_card controls whether this task point gives the shared restore-link
## card; it is enabled by default because the document says both players can get that
## card from task points.
@export var grants_restore_card: bool = true

## visual_path points to the editable marker mesh that designers can recolor, resize,
## or replace without changing the pickup logic.
@export var visual_path: NodePath = NodePath("Visual")

## collected records whether this task point has already been used so repeated
## overlaps cannot grant duplicate cards.
var collected: bool = false

## visual caches the editable marker mesh for disabling after collection.
@onready var visual: Node3D = get_node(visual_path) as Node3D


## _ready registers the point for main-scene discovery and connects body overlap
## detection to the ownership check.
func _ready() -> void:
	add_to_group("task_points")
	body_entered.connect(_on_body_entered)


## _on_body_entered validates that the body is a player and matches allowed_player_id
## before emitting the one-time collection signal.
func _on_body_entered(body: Node) -> void:
	if collected:
		return

	if not body.has_method("get_player_id"):
		return

	var entering_player_id: int = int(body.call("get_player_id"))
	if entering_player_id != allowed_player_id:
		return

	set_collected(true)
	task_point_collected.emit(self, entering_player_id)


## set_collected updates the logical collected flag, hides the visual marker, and
## turns off monitoring so the point no longer reacts after being used.
func set_collected(new_collected: bool) -> void:
	collected = new_collected
	monitoring = not collected
	if is_instance_valid(visual):
		visual.visible = not collected
