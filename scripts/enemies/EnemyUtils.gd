extends RefCounted

class_name EnemyUtils

static func get_root():
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root

static func get_main_scene():
	return get_root().get_node('MainScene')

static func get_body_core() -> Node2D:
	return get_root().get_node('MainScene/Actors/BodyCore') as Node2D

static func force_left(v: Vector2):
	if v.x > 0:
		return Vector2.LEFT
	return v
