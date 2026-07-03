class_name CardDeck
extends RefCounted

## CardKind defines the two card base categories required by the design document.
## ATTACK cards cycle back to the bottom of the ordered pile after use, while OTHER
## cards are consumed and removed from the current battle after use.
enum CardKind {
	ATTACK,
	OTHER,
}

## PLAY_COOLDOWN_SECONDS is the mandatory delay after any card is played before
## the same player may play another card.
const PLAY_COOLDOWN_SECONDS: float = 2.0

## RESTORE_CARD_ID is the stable identifier for the shared thirteenth card that
## restores the link and refills the flesh core health.
const RESTORE_CARD_ID: StringName = &"restore_link"

## owner_player_id records which player owns this independent ordered card pile.
var owner_player_id: int = 1

## cards stores the current ordered pile; index 0 is the visible top card that may
## be played or skipped, and later indexes are deeper in the pile.
var cards: Array[Dictionary] = []

## consumed_cards keeps OTHER cards that were played and removed from the active
## battle, which is useful for debugging and for future battle summary UI.
var consumed_cards: Array[Dictionary] = []

## cooldown_remaining stores how many seconds are left before this player may play
## another card after the required two second play delay.
var cooldown_remaining: float = 0.0


## _init prepares a deck for the requested owner and fills it with the six-card
## starting pile assigned to that player.
func _init(new_owner_player_id: int = 1) -> void:
	owner_player_id = new_owner_player_id
	cards = _build_initial_cards(owner_player_id)


## _build_initial_cards returns the six starting cards for one player. The document
## says exact future card content will be filled in later, so these cards implement
## distinct responsibilities without locking final balance.
func _build_initial_cards(new_owner_player_id: int) -> Array[Dictionary]:
	if new_owner_player_id == 1:
		return [
			_make_card(&"p1_attack_anchor", "牵制射击", CardKind.ATTACK, 18.0, 12.0, "玩家一的攻击牌，用于优先清理靠近连线中心的敌人。"),
			_make_card(&"p1_attack_guard", "近身护线", CardKind.ATTACK, 14.0, 8.0, "玩家一的攻击牌，代表保护肉体附近空间的近距离输出。"),
			_make_card(&"p1_other_brace", "稳住连线", CardKind.OTHER, 0.0, 0.0, "玩家一的其他牌，占位给未来的减阻或抗拉扯效果。"),
			_make_card(&"p1_attack_push", "推离冲击", CardKind.ATTACK, 10.0, 10.0, "玩家一的攻击牌，占位给未来击退型攻击。"),
			_make_card(&"p1_other_signal", "上路呼叫", CardKind.OTHER, 0.0, 0.0, "玩家一的其他牌，强调上路任务职责。"),
			_make_card(&"p1_attack_finish", "断点补刀", CardKind.ATTACK, 24.0, 7.0, "玩家一的攻击牌，用于高伤害但短距离的终结。"),
		]

	return [
		_make_card(&"p2_attack_mark", "标记射击", CardKind.ATTACK, 12.0, 16.0, "玩家二的攻击牌，用于更远距离地标记并伤害敌人。"),
		_make_card(&"p2_other_scan", "下路侦察", CardKind.OTHER, 0.0, 0.0, "玩家二的其他牌，强调下路任务职责。"),
		_make_card(&"p2_attack_arc", "弧线打击", CardKind.ATTACK, 16.0, 14.0, "玩家二的攻击牌，占位给未来绕过障碍的远程输出。"),
		_make_card(&"p2_attack_cover", "掩护火力", CardKind.ATTACK, 13.0, 12.0, "玩家二的攻击牌，用于给玩家一移动时提供掩护。"),
		_make_card(&"p2_other_focus", "同步呼吸", CardKind.OTHER, 0.0, 0.0, "玩家二的其他牌，占位给未来协同或冷却调整效果。"),
		_make_card(&"p2_attack_pierce", "穿刺点射", CardKind.ATTACK, 20.0, 10.0, "玩家二的攻击牌，用于中距离高伤害输出。"),
	]


## _make_card creates one card dictionary with stable keys used by UI and gameplay
## code, keeping the deck rules independent from visual presentation.
func _make_card(card_id: StringName, display_name: String, card_kind: int, damage: float, range: float, description: String) -> Dictionary:
	return {
		"id": card_id,
		"display_name": display_name,
		"kind": card_kind,
		"damage": damage,
		"range": range,
		"description": description,
	}


## update_cooldown reduces the remaining play delay over time while clamping it to
## zero so UI can display a stable ready state.
func update_cooldown(delta: float) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)


## can_play_current_card reports whether the top card is available and the required
## two second cooldown has fully expired.
func can_play_current_card() -> bool:
	return not cards.is_empty() and cooldown_remaining <= 0.0


## get_current_card returns the top card without changing the ordered pile. An
## empty dictionary means the player has no active cards left.
func get_current_card() -> Dictionary:
	if cards.is_empty():
		return {}
	return cards[0]


## try_play_current_card applies the document's pile rule: attack cards go to the
## bottom, other cards are consumed, and any successful play starts a two second
## cooldown before the next card can be played.
func try_play_current_card() -> Dictionary:
	if cards.is_empty():
		return {"played": false, "reason": "empty"}

	if cooldown_remaining > 0.0:
		return {"played": false, "reason": "cooldown"}

	var played_card: Dictionary = cards.pop_front()
	if int(played_card["kind"]) == CardKind.ATTACK:
		cards.append(played_card)
	else:
		consumed_cards.append(played_card)

	cooldown_remaining = PLAY_COOLDOWN_SECONDS
	return {"played": true, "card": played_card}


## skip_current_card lets a player choose not to play the visible card. Skipping
## rotates the card to the bottom without triggering the two second play cooldown.
func skip_current_card() -> Dictionary:
	if cards.is_empty():
		return {"skipped": false, "reason": "empty"}

	var skipped_card: Dictionary = cards.pop_front()
	cards.append(skipped_card)
	return {"skipped": true, "card": skipped_card}


## add_restore_card_if_missing appends the shared thirteenth restore card when a
## valid task point is collected, while avoiding duplicate active restore cards.
func add_restore_card_if_missing() -> bool:
	for card: Dictionary in cards:
		if card.get("id", &"") == RESTORE_CARD_ID:
			return false

	cards.append(_make_card(RESTORE_CARD_ID, "恢复连线", CardKind.OTHER, 0.0, 0.0, "两个玩家都能在任务点取得的共享牌，用于恢复断开的连线并回满肉体血量。"))
	return true


## get_current_card_label returns a compact UI label that includes cooldown state
## and the current pile size for the visible top card.
func get_current_card_label() -> String:
	if cards.is_empty():
		return "无可用卡牌"

	var current_card: Dictionary = get_current_card()
	var kind_label: String = "攻击" if int(current_card["kind"]) == CardKind.ATTACK else "其他"
	if cooldown_remaining > 0.0:
		return "%s [%s] 冷却 %.1fs / 剩余 %d" % [current_card["display_name"], kind_label, cooldown_remaining, cards.size()]

	return "%s [%s] 可打出 / 剩余 %d" % [current_card["display_name"], kind_label, cards.size()]
