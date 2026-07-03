extends RefCounted
class_name CardDeck

# 脚本说明：
# - CARD_TYPE_ATTACK：攻击牌类型标识。攻击牌被打出后不会离开战斗，而是移动到牌堆底部，用来满足文档中“攻击牌打出后会被放到牌堆底部”的规则。
# - CARD_TYPE_OTHER：其他牌类型标识。其他牌被打出后会从当前战斗牌堆中移除，用来满足文档中“其他牌打出后会消耗并且从战斗中移除”的规则。
# - CARD_RESTORE_LINK_ID：恢复连线卡的唯一牌 ID。任务点发放这张牌，玩家打出后由主控制器恢复肉体血量和连线状态。
# - PLAY_COOLDOWN_SECONDS：每次真正打出一张牌后的公共冷却时间。文档明确要求每张牌打出后 2 秒才能打下一张牌。
# - PASS_COOLDOWN_SECONDS：玩家选择不打出当前牌后的冷却时间。新版文档要求这张牌放到牌堆底部，并等待 2 秒后查看下一张。
# - owner_player_id：这个牌堆属于哪个玩家。主控制器用它区分两个独立牌池，UI 也用它显示对应玩家的当前牌。
# - cards：当前战斗中的有序牌堆。数组第 0 张就是当前可打出的牌，后续顺序保持栈/牌堆语义。
# - cooldown_remaining：距离该牌堆下一次允许操作还剩多少秒。打出牌或把当前牌放到底部后都会变成 2 秒，随后每帧递减。
# - last_played_card：最近一次打出或放到底部的牌。它用于调试和 UI 文案，不参与牌堆顺序判定。
# - passed_cards：玩家选择“不打出这张牌并放到底部”的累计次数。它保留设计信息，便于后续根据弃打次数加入惩罚或提示。
# - setup(new_owner_player_id, initial_cards)：初始化牌堆所属玩家和初始牌组，复制传入字典以避免两个玩家误共享同一张牌数据。
# - tick(delta)：推进冷却计时器，让主控制器每个物理帧调用一次即可。
# - can_act()：判断当前牌堆是否有牌并且不在冷却中。
# - has_cards()：只判断当前战斗牌堆是否还有牌，用于 UI 和逻辑保护。
# - peek_current_card()：读取当前牌但不改变牌堆，用于 HUD 显示。
# - play_current_card()：执行打牌规则；攻击牌放到底部，其他牌移出战斗，并启动 2 秒冷却。
# - pass_current_card()：表示玩家选择不打出当前牌；当前牌移动到牌堆底部，并启动 2 秒冷却，冷却后可查看下一张牌。
# - add_card(card_data)：把任务点奖励或后续系统生成的牌加入牌堆底部。
# - card_count()：返回当前战斗牌堆数量，用于 HUD 显示。
# - current_card_name()：返回当前牌名；没有牌时返回“无牌”。
# - make_card(card_id, display_name, card_type, description)：创建标准卡牌字典，保证所有牌都有统一字段。
# - make_restore_link_card()：创建恢复连线卡，确保任务点获得的第 13 张牌在两个玩家那里表现一致。

const CARD_TYPE_ATTACK := "attack"
const CARD_TYPE_OTHER := "other"
const CARD_RESTORE_LINK_ID := "restore_link"
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
	for card_data in initial_cards:
		cards.append(card_data.duplicate(true))
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


func play_current_card() -> Dictionary:
	if not can_act():
		return {}

	var played_card: Dictionary = cards.pop_front()
	last_played_card = played_card.duplicate(true)
	cooldown_remaining = PLAY_COOLDOWN_SECONDS

	if played_card.get("type", CARD_TYPE_OTHER) == CARD_TYPE_ATTACK:
		cards.append(played_card.duplicate(true))

	return played_card


func pass_current_card() -> Dictionary:
	if cooldown_remaining > 0.0 or cards.is_empty():
		return {}

	var passed_card: Dictionary = cards.pop_front()
	cards.append(passed_card.duplicate(true))
	passed_cards += 1
	last_played_card = passed_card.duplicate(true)
	cooldown_remaining = PASS_COOLDOWN_SECONDS
	return last_played_card.duplicate(true)


func add_card(card_data: Dictionary) -> void:
	cards.append(card_data.duplicate(true))


func card_count() -> int:
	return cards.size()


func current_card_name() -> String:
	if cards.is_empty():
		return "无牌"
	return str(cards[0].get("name", "未命名牌"))


static func make_card(card_id: String, display_name: String, card_type: String, description: String) -> Dictionary:
	return {
		"id": card_id,
		"name": display_name,
		"type": card_type,
		"description": description,
	}


static func make_restore_link_card() -> Dictionary:
	return make_card(
		CARD_RESTORE_LINK_ID,
		"恢复连线",
		CARD_TYPE_OTHER,
		"任务点获得的第 13 张牌。打出后恢复肉体满血并重新连接两个玩家。"
	)
