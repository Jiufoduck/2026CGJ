extends RefCounted
class_name CardCatalog

# 脚本说明：
# - RESTORE_CARD_ID：恢复连线牌的唯一 ID。牌堆、非法出牌判断和恢复生成效果都复用它。
# - REWARD_CHOICE_COUNT：任务点奖励三选一的候选数量。
# - CardDefinitionScript：卡牌资源脚本预加载，保证静态方法能识别资源字段。
# - ALL_DEFINITIONS：13 张卡牌资源列表。每张卡的数值放在对应 .tres 中。
# - INITIAL_DECK_IDS_BY_PLAYER：每名玩家的初始牌组 ID。当前规则是每人 3 张。
# - REWARD_POOL_IDS_BY_PLAYER：每名玩家奖励池 ID。任务点奖励不会包含恢复牌。
# - get_all_definitions()：返回 13 张卡牌资源，供测试和调试检查唯一性。
# - get_definition(card_id)：按 ID 查找卡牌资源。
# - make_card_data(card_id)：把某张卡牌资源复制成牌堆可保存的运行时字典。
# - make_initial_deck(player_id)：创建指定玩家的初始牌组字典数组。
# - make_reward_choices(player_id, rng)：从指定玩家奖励池随机抽 3 张不同牌。
# - make_restore_card()：创建恢复连线牌字典，供恢复生成效果加入牌堆。
# - card_is_restore(card_data)：判断一张运行时牌是否是恢复牌；奖励池会排除这种牌。
# - _card_id_is_reward_eligible(card_id)：判断某个资源 ID 是否允许进入任务点奖励。
# - _make_cards_from_ids(card_ids)：把一组 ID 转成运行时字典数组。

const RESTORE_CARD_ID := "restore_link"
const REWARD_CHOICE_COUNT := 3
const CardDefinitionScript = preload("res://scripts/card/CardDefinition.gd")

const ALL_DEFINITIONS := [
	preload("res://resources/cards/a1_range_damage.tres"),
	preload("res://resources/cards/a2_collision_charge.tres"),
	preload("res://resources/cards/a3_counterattack.tres"),
	preload("res://resources/cards/a4_clear_screen.tres"),
	preload("res://resources/cards/a5_restore_generation.tres"),
	preload("res://resources/cards/a6_phase_walk.tres"),
	preload("res://resources/cards/b7_knockback.tres"),
	preload("res://resources/cards/b8_cd_distribution.tres"),
	preload("res://resources/cards/b9_group_freeze.tres"),
	preload("res://resources/cards/b10_optimize_hand.tres"),
	preload("res://resources/cards/b11_focused_fire.tres"),
	preload("res://resources/cards/b12_damage_boost.tres"),
	preload("res://resources/cards/restore_link.tres"),
]

const INITIAL_DECK_IDS_BY_PLAYER := {
	1: [RESTORE_CARD_ID, "a1_range_damage", "a2_collision_charge"],
	2: [RESTORE_CARD_ID, "b7_knockback", "b12_damage_boost"],
}

const REWARD_POOL_IDS_BY_PLAYER := {
	1: ["a1_range_damage", "a2_collision_charge", "a3_counterattack", "a4_clear_screen", "a5_restore_generation", "a6_phase_walk"],
	2: ["b7_knockback", "b8_cd_distribution", "b9_group_freeze", "b10_optimize_hand", "b11_focused_fire", "b12_damage_boost"],
}


static func get_all_definitions() -> Array:
	return ALL_DEFINITIONS.duplicate()


static func get_definition(card_id: String) -> CardDefinition:
	for definition in ALL_DEFINITIONS:
		if definition.id == card_id:
			return definition
	return null


static func make_card_data(card_id: String) -> Dictionary:
	var definition := get_definition(card_id)
	if definition == null:
		return {}
	return definition.to_card_data()


static func make_initial_deck(player_id: int) -> Array:
	return _make_cards_from_ids(INITIAL_DECK_IDS_BY_PLAYER.get(player_id, []))


static func make_reward_choices(player_id: int, rng: RandomNumberGenerator = null) -> Array:
	var reward_ids: Array = []
	for card_id in REWARD_POOL_IDS_BY_PLAYER.get(player_id, []):
		if _card_id_is_reward_eligible(str(card_id)):
			reward_ids.append(str(card_id))

	var reward_cards: Array = []
	if reward_ids.is_empty():
		return reward_cards

	var local_rng := rng
	if local_rng == null:
		local_rng = RandomNumberGenerator.new()
		local_rng.randomize()

	while reward_cards.size() < REWARD_CHOICE_COUNT and not reward_ids.is_empty():
		var chosen_index: int = local_rng.randi_range(0, reward_ids.size() - 1)
		var card_data := make_card_data(str(reward_ids[chosen_index]))
		if not card_data.is_empty() and not card_is_restore(card_data):
			reward_cards.append(card_data)
		reward_ids.remove_at(chosen_index)
	return reward_cards


static func make_restore_card() -> Dictionary:
	return make_card_data(RESTORE_CARD_ID)


static func card_is_restore(card_data: Dictionary) -> bool:
	if str(card_data.get("id", "")) == RESTORE_CARD_ID:
		return true
	for tag_value in card_data.get("tags", []):
		if str(tag_value) == CardDefinitionScript.TAG_RESTORE:
			return true
	return false


static func _card_id_is_reward_eligible(card_id: String) -> bool:
	if card_id == RESTORE_CARD_ID:
		return false
	var card_data := make_card_data(card_id)
	return not card_data.is_empty() and not card_is_restore(card_data)


static func _make_cards_from_ids(card_ids: Array) -> Array:
	var cards: Array = []
	for card_id in card_ids:
		var card_data := make_card_data(str(card_id))
		if not card_data.is_empty():
			cards.append(card_data)
	return cards
