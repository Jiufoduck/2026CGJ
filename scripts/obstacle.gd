@tool
class_name RectObstacle
extends StaticBody3D

## mesh_instance_path points to the editable whitebox mesh whose material UV scale
## is adjusted when the obstacle node is scaled.
@export var mesh_instance_path: NodePath = NodePath("MeshInstance3D")

## collision_shape_path points to the editable rectangular collision shape that makes
## the obstacle block players and enemies.
@export var collision_shape_path: NodePath = NodePath("CollisionShape3D")

## texture_world_tile_size describes how many world units one material tile should
## cover on each axis so scaling the whitebox does not visibly stretch its texture.
@export var texture_world_tile_size: Vector3 = Vector3(2.0, 2.0, 2.0)

## mesh_instance caches the visible obstacle mesh so material updates do not need a
## repeated scene-tree lookup.
@onready var mesh_instance: MeshInstance3D = get_node_or_null(mesh_instance_path) as MeshInstance3D

## collision_shape caches the collision node for future editor-time validation and
## keeps the scene explicitly documented.
@onready var collision_shape: CollisionShape3D = get_node_or_null(collision_shape_path) as CollisionShape3D

## last_known_scale stores the previous node scale so the script updates UV tiling
## only when the designer actually changes the obstacle size.
var last_known_scale: Vector3 = Vector3.ZERO


## _ready duplicates any shared material and performs an initial texture tiling sync
## for both editor preview and gameplay.
func _ready() -> void:
	_make_material_unique()
	_sync_texture_scale()


## _process watches for scale edits so manually placed obstacles keep their internal
## texture density stable even when their whitebox scale changes.
func _process(_delta: float) -> void:
	if scale != last_known_scale:
		_sync_texture_scale()


## _make_material_unique prevents one obstacle's UV tiling changes from changing
## every other instance that happens to share the same material resource.
func _make_material_unique() -> void:
	if not is_instance_valid(mesh_instance):
		return

	var active_material: Material = mesh_instance.get_active_material(0)
	if active_material == null:
		var new_material: StandardMaterial3D = StandardMaterial3D.new()
		new_material.albedo_color = Color(0.86, 0.86, 0.82)
		mesh_instance.set_surface_override_material(0, new_material)
		return

	mesh_instance.set_surface_override_material(0, active_material.duplicate())


## _sync_texture_scale sets StandardMaterial3D UV tiling from the current world scale
## so a scaled rectangle shows repeated texture detail instead of stretched detail.
func _sync_texture_scale() -> void:
	last_known_scale = scale
	if not is_instance_valid(mesh_instance):
		return

	var active_material: Material = mesh_instance.get_active_material(0)
	if active_material is StandardMaterial3D:
		var standard_material: StandardMaterial3D = active_material as StandardMaterial3D
		standard_material.uv1_scale = Vector3(
			maxf(absf(scale.x) / maxf(texture_world_tile_size.x, 0.01), 0.01),
			maxf(absf(scale.y) / maxf(texture_world_tile_size.y, 0.01), 0.01),
			maxf(absf(scale.z) / maxf(texture_world_tile_size.z, 0.01), 0.01)
		)
