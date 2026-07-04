extends RefCounted
class_name SoundCue


static func play(context: Node, sound_name: StringName, volume_db = null, pitch = null, delay = null) -> void:
	var sound_manager := _get_sound_manager(context)
	if sound_manager == null:
		return
	if sound_manager.has_method("has_sound") and not bool(sound_manager.call("has_sound", sound_name)):
		return
	if sound_manager.has_method("play"):
		sound_manager.call("play", sound_name, volume_db, pitch, delay)


static func play_random(context: Node, sound_names: Array[StringName], volume_db = null, pitch = null, delay = null) -> void:
	if sound_names.is_empty():
		return
	var chosen_index := randi() % sound_names.size()
	play(context, sound_names[chosen_index], volume_db, pitch, delay)


static func play_music(context: Node, sound_name: StringName, volume_db = null, pitch = null, restart := true, loop := true) -> void:
	var sound_manager := _get_sound_manager(context)
	if sound_manager == null:
		return
	if sound_manager.has_method("has_sound") and not bool(sound_manager.call("has_sound", sound_name)):
		return
	if sound_manager.has_method("play_music"):
		sound_manager.call("play_music", sound_name, volume_db, pitch, restart, loop)


static func stop_music(context: Node) -> void:
	var sound_manager := _get_sound_manager(context)
	if sound_manager != null and sound_manager.has_method("stop_music"):
		sound_manager.call("stop_music")


static func _get_sound_manager(context: Node) -> Node:
	if context == null:
		return null
	var tree := context.get_tree()
	if tree == null:
		return null
	if tree.root == null:
		return null
	return tree.root.get_node_or_null("SoundManager")
