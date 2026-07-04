extends SceneTree


func _initialize() -> void:
	var scene := load("res://scenes/ui/player_card_panel.tscn")
	var panel: Control = scene.instantiate()
	root.add_child(panel)
	await process_frame

	var attack_card := {
		"id": "A1",
		"name": "范围伤害",
		"description": "以肉体为中心造成范围伤害。",
		"type": "attack",
		"tags": [],
		"owner_player_id": 1,
	}
	var enhance_card := {
		"id": "A6",
		"name": "穿墙",
		"description": "断裂连线并允许玩家穿过普通障碍。",
		"type": "other",
		"tags": ["consumable"],
		"owner_player_id": 1,
	}
	panel.load_card_stack_data([attack_card, enhance_card, attack_card], attack_card, 3, 0.0, 1)
	await process_frame

	var stack_layer: Control = panel.get_node("CardStackLayer")
	var title: Label = panel.get_node("VBoxContainer/CardTitle")
	var description: Label = panel.get_node("VBoxContainer/CardDescrip")
	var count_label: Label = panel.get_node("Label")
	var top_card := stack_layer.get_child(stack_layer.get_child_count() - 1) as TextureRect

	var failures := []
	if stack_layer.z_index < 0:
		failures.append("stack layer is behind panel")
	if stack_layer.get_child_count() != 3:
		failures.append("expected 3 card textures, got %d" % stack_layer.get_child_count())
	if top_card == null or top_card.texture == null:
		failures.append("top card texture is missing")
	if title.text != "范围伤害":
		failures.append("title not rendered")
	if description.text.is_empty():
		failures.append("description not rendered")
	if count_label.text != "x3":
		failures.append("count label not rendered")
	if title.z_index <= top_card.z_index:
		failures.append("title is not above card art")

	if failures.is_empty():
		print("PLAYER_HAND_STACK_VISUAL_SMOKE_OK")
	else:
		push_error("; ".join(failures))
	quit(0 if failures.is_empty() else 1)
