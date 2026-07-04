extends RefCounted
class_name CardDeck

# 脚本说明：
# - CARD_TYPE_ATTACK：HUD 显示用攻击牌类型标识。具体是否消耗不再由类型决定，而由 tags 决定。
# - CARD_TYPE_OTHER：HUD 显示用其他牌类型标识。具体是否消耗不再由类型决定，而由 tags 决定。
# - CARD_RESTORE_LINK_ID：恢复连线卡的唯一 ID。恢复生成、非法出牌判断和旧接口都复用它。
# - TAG_CONSUMABLE：消耗词条。带它的牌成功打出后会被移除。
# - TAG_BREAK_LINK：断裂词条。带它的牌成功打出后会断线，断线期间不能打出。
# - TAG_RESTORE：恢复词条。带它的牌只能在断线期间打出，并且恢复牌强制不是消耗牌。
# - PLAY_COOLDOWN_SECONDS：没有资源冷却字段时使用的默认出牌 CD。
# - PASS_COOLDOWN_SECONDS：合法跳过当前牌时使用的默认 CD；非法牌跳过会传入 0 秒。
# - owner_player_id：这个牌堆属于哪个玩家。主控制器用它区分两个独立牌池。
# - cards：当前战斗牌堆。每个元素都是一张运行时卡牌字典，同名牌可以有多份副本。
# - cooldown_remaining：距离下一次允许打出或跳过还剩多少秒。
# - last_played_card：最近一次成功打出或跳过的牌，用于调试和 HUD 消息。
# - passed_cards：累计跳过次数，保留给后续调试或惩罚规则。
# - setup(new_owner_player_id, initial_cards)：初始化牌堆并复制初始牌，避免共享同一张字典。
# - tick(delta)：推进冷却计时器。
# - can_act()：判断当前牌堆是否有牌且冷却结束。
# - has_cards()：返回牌堆是否仍有牌。
# - peek_current_card()：读取当前牌副本，不改变牌堆。
# - is_current_card_playable(link_is_active)：按恢复/断裂规则判断当前牌在当前连线状态下能否打出。
# - play_current_card(link_is_active, cooldown_seconds)：尝试打出当前牌，合法才移动牌堆并启动 CD。
# - pass_current_card(cooldown_seconds)：把当前牌放到底部，使用传入 CD；非法牌可传 0 秒防止卡死。
# - add_card(card_data)：把一张牌副本加入牌堆底部。
# - add_cards(card_list)：把多张牌副本依次加入牌堆底部。
# - card_count()：返回当前牌堆张数。
# - get_cards_snapshot()：读取整副牌的深拷贝，用于 HUD 堆叠显示，不改变牌堆。
# - current_card_name()：返回当前牌名，没有牌时返回“无牌”。
# - set_cooldown_remaining(seconds)：直接设置当前 CD，供特殊卡牌覆盖 CD。
# - multiply_cooldown(multiplier)：按倍率调整当前剩余 CD，供 B8 CD 分配使用。
# - make_random_consumable_card_free(rng)：随机让一张消耗牌失去消耗词条，供 B10 优化手牌使用。
# - card_has_tag(card_data, tag)：静态工具，判断某张运行时牌是否带指定词条。
# - card_is_consumable(card_data)：静态工具，判断某张牌成功打出后是否消耗。
# - make_card(card_id, display_name, card_type, description, tags, effect_id)：旧手动奖励接口的兼容造牌方法。
# - make_restore_link_card()：旧接口兼容方法，创建一张基础恢复牌。

const CARD_TYPE_ATTACK := "attack"
const CARD_TYPE_OTHER := "other"
const CARD_RESTORE_LINK_ID := "restore_link"
const TAG_CONSUMABLE := "consumable"
const TAG_BREAK_LINK := "break"
const TAG_RESTORE := "restore"
const PLAY_COOLDOWN_SECONDS := 2.0
const PASS_COOLDOWN_SECONDS := 2.0

var owner_player_id := 0
var cards: Array = []
var cooldown_remaining := 0.0
var last_played_card: Dictionary = {}
var passed_cards := 0


func setup(new_owner_player_id: int, initial_cards: Array) -> void:
	owner_player_id = new_owner_player_id
	cards.clear()
	add_cards(initial_cards)
	cooldown_remaining = 0.0
	last_played_card = {}
	passed_cards = 0


func tick(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)


func can_act() -> bool:
	return cooldown_remaining <= 0.0 and has_cards()


func has_cards() -> bool:
	return not cards.is_empty()


func peek_current_card() -> Dictionary:
	if cards.is_empty():
		return {}
	return cards[0].duplicate(true)


func get_cards_snapshot() -> Array:
	var snapshot := []
	for card_data in cards:
		if card_data is Dictionary:
			snapshot.append((card_data as Dictionary).duplicate(true))
	return snapshot


func is_current_card_playable(link_is_active: bool) -> bool:
	if cards.is_empty():
		return false
	return _card_is_playable_in_link_state(cards[0], link_is_active)


func play_current_card(link_is_active: bool, cooldown_seconds := -1.0) -> Dictionary:
	if not can_act() or not is_current_card_playable(link_is_active):
		return {}

	var played_card: Dictionary = cards.pop_front()
	last_played_card = played_card.duplicate(true)
	var final_cooldown := cooldown_seconds
	if final_cooldown < 0.0:
		final_cooldown = float(played_card.get("base_cooldown", PLAY_COOLDOWN_SECONDS))
	cooldown_remaining = maxf(0.0, final_cooldown)

	if not card_is_consumable(played_card):
		cards.append(played_card.duplicate(true))
	return played_card.duplicate(true)


func pass_current_card(cooldown_seconds := PASS_COOLDOWN_SECONDS) -> Dictionary:
	if cooldown_remaining > 0.0 or cards.is_empty():
		return {}

	var passed_card: Dictionary = cards.pop_front()
	cards.append(passed_card.duplicate(true))
	passed_cards += 1
	last_played_card = passed_card.duplicate(true)
	cooldown_remaining = maxf(0.0, cooldown_seconds)
	return last_played_card.duplicate(true)


func add_card(card_data: Dictionary) -> void:
	if card_data.is_empty():
		return
	cards.append(card_data.duplicate(true))


func add_cards(card_list: Array) -> void:
	for card_data in card_list:
		if card_data is Dictionary:
			add_card(card_data)


func card_count() -> int:
	return cards.size()

func current_card_name() -> String:
	if cards.is_empty():
		return "无牌"
	return str(cards[0].get("name", "未命名牌"))


func set_cooldown_remaining(seconds: float) -> void:
	cooldown_remaining = maxf(0.0, seconds)


func multiply_cooldown(multiplier: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining * multiplier)


func make_random_consumable_card_free(rng: RandomNumberGenerator) -> Dictionary:
	var candidate_indices: Array[int] = []
	for index in range(cards.size()):
		if card_is_consumable(cards[index]):
			candidate_indices.append(index)

	if candidate_indices.is_empty():
		return {}

	var chosen_index: int = candidate_indices[rng.randi_range(0, candidate_indices.size() - 1)]
	var chosen_card: Dictionary = cards[chosen_index]
	var card_tags: Array = Array(chosen_card.get("tags", []))
	card_tags.erase(TAG_CONSUMABLE)
	chosen_card["tags"] = card_tags
	chosen_card["description"] = "%s\n已优化：这张牌打出后不再被移除。" % str(chosen_card.get("description", ""))
	cards[chosen_index] = chosen_card
	return chosen_card.duplicate(true)


static func card_has_tag(card_data: Dictionary, tag: String) -> bool:
	for tag_value in card_data.get("tags", []):
		if str(tag_value) == tag:
			return true
	return false


static func card_is_consumable(card_data: Dictionary) -> bool:
	if card_has_tag(card_data, TAG_RESTORE):
		return false
	return card_has_tag(card_data, TAG_CONSUMABLE)


static func make_card(card_id: String, display_name: String, card_type: String, description: String, tags: Array = [], effect_id := "") -> Dictionary:
	return {
		"id": card_id,
		"name": display_name,
		"type": card_type,
		"tags": tags.duplicate(true),
		"description": description,
		"effect_id": effect_id,
		"base_cooldown": PLAY_COOLDOWN_SECONDS,
	}


static func make_restore_link_card() -> Dictionary:
	return make_card(
		CARD_RESTORE_LINK_ID,
		"恢复连线",
		CARD_TYPE_OTHER,
		"恢复牌。连线期间不能打出；断线期间打出后恢复肉体满血并重新连接两个玩家。",
		[TAG_RESTORE],
		"restore_link"
	)


func promote_first_restore_to_top() -> Dictionary:
	for i in range(cards.size()):
		if card_has_tag(cards[i], TAG_RESTORE):
			if i > 0:
				var card = cards.pop_at(i)
				cards.insert(0, card)
			return cards[0].duplicate(true)
	return {}


func _card_is_playable_in_link_state(card_data: Dictionary, link_is_active: bool) -> bool:
	if card_has_tag(card_data, TAG_RESTORE) and link_is_active:
		return false
	if card_has_tag(card_data, TAG_BREAK_LINK) and not link_is_active:
		return false
	return true
