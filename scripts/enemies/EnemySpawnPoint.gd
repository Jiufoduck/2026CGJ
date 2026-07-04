extends Node2D
class_name EnemySpawnPoint

# 脚本说明：
# - enemy_scene：这个生成点要生成的固定敌人场景。主场景里每个生成点都可以指定 EnemyType1、EnemyType2 或 EnemyType3。
# - spawn_on_ready：是否在生成点进入场景时自动生成敌人。默认开启，满足文档中“固定种类敌人会在主场景里摆放的生成点生成”的要求。
# - spawn_label：生成点显示用的短标签。它用于编辑器和运行时辨认生成点对应的难度段或敌人类型。
# - spawned_enemy：已经由这个生成点生成出来的敌人实例引用。它防止同一个生成点重复生成敌人。
# - spawn_loop_generation：生成循环版本号。Try again 会递增它，让旧的异步等待自然失效。
# - marker_visual：生成点白模标记节点引用。节点在 EnemySpawnPoint.tscn 中，可在 tscn 内修改外观。
# - label_node：生成点文字节点引用。节点在 EnemySpawnPoint.tscn 中，可在 tscn 内修改字号和位置。
# - _ready()：刷新生成点显示，并按配置自动生成一次固定种类敌人。
# - start_spawn_loop()：启动一条受版本号保护的接近生成循环。
# - reset_spawn_point()：Try again 时清掉旧敌人并重新等待玩家接近。
# - spawn_enemy()：实例化 enemy_scene，把敌人作为生成点的子节点放在生成点坐标。
# - clear_spawned_enemy()：清理当前生成的敌人引用；后续如果需要重刷敌人，可以先调用它。
# - _refresh_label()：根据 spawn_label 和 enemy_scene 更新生成点显示文字。

@export var enemy_scene: PackedScene
@export var spawn_label := "敌人生成点"
var spawn_distance = 1100
@export var spawn_distance_override = 0
@export_multiline var custom_script: String

var spawned_enemy: Node2D
var spawn_loop_generation := 0

@onready var marker_visual: Polygon2D = $Marker
@onready var label_node: Label = $Label


func _ready() -> void:
	add_to_group("enemy_spawn_points")
	_refresh_label()
	if spawn_distance_override > 0:
		spawn_distance = spawn_distance_override
	start_spawn_loop()


func start_spawn_loop() -> void:
	spawn_loop_generation += 1
	_run_spawn_loop(spawn_loop_generation)


func reset_spawn_point() -> void:
	spawn_loop_generation += 1
	clear_spawned_enemy()
	_run_spawn_loop(spawn_loop_generation)


func _run_spawn_loop(loop_generation: int) -> void:
	while is_inside_tree() and loop_generation == spawn_loop_generation:
		await get_tree().create_timer(1.0, false).timeout
		if not is_inside_tree() or loop_generation != spawn_loop_generation:
			return

		var core = EnemyUtils.get_body_core()
		if core == null or not is_instance_valid(core):
			continue

		var dis_x: float = absf((core.global_position - global_position).x)
		if dis_x < spawn_distance:
			spawn_enemy()
			return


func spawn_enemy() -> Node2D:
	if enemy_scene == null:
		push_error('enemy_scene not set!')
		return spawned_enemy
	if spawned_enemy != null:
		return spawned_enemy

	var instance := enemy_scene.instantiate() as EnemyBase

	spawned_enemy = instance
	if not custom_script.is_empty():
		var gds = GDScript.new()
		gds.source_code = custom_script
		if gds.reload() == OK:
			gds.call('main', instance)
	add_child(spawned_enemy)
	spawned_enemy.position = Vector2.ZERO

	print('enemy spawned: %d' % spawned_enemy.enemy_type_id)
	return spawned_enemy


func clear_spawned_enemy() -> void:
	if spawned_enemy != null and is_instance_valid(spawned_enemy) and not spawned_enemy.is_queued_for_deletion():
		spawned_enemy.queue_free()
	spawned_enemy = null


func _refresh_label() -> void:
	if label_node == null:
		return

	var scene_name := "未设置"
	if enemy_scene != null:
		scene_name = enemy_scene.resource_path.get_file().get_basename()
	label_node.text = "%s\n%s" % [spawn_label, scene_name]
