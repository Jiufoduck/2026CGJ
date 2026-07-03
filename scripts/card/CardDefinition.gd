extends Resource
class_name CardDefinition

# 脚本说明：
# - TAG_CONSUMABLE：消耗牌词条。带这个标签的牌成功打出后不会回到牌堆底部。
# - TAG_BREAK_LINK：断裂牌词条。带这个标签的牌成功打出后会使连线断裂，并且断线期间不能打出。
# - TAG_RESTORE：恢复牌词条。带这个标签的牌只能在断线期间打出，并且恢复牌不是消耗牌。
# - id：卡牌唯一 ID。牌堆、奖励池和效果执行器都通过它识别具体卡牌。
# - card_name：卡牌显示名称。HUD 和奖励三选一按钮会读取它。
# - owner_player_id：卡牌所属玩家。1 代表 A 卡池玩家，2 代表 B 卡池玩家，0 代表通用恢复牌。
# - card_type：HUD 显示用的牌类型。attack 显示为攻击牌，other 显示为其他牌。
# - tags：卡牌词条数组，例如 consumable、break、restore。规则判断只读这里，不再硬编码某张牌。
# - description：卡牌说明文本。奖励按钮会显示它，方便确认当前资源数值。
# - effect_id：效果执行器使用的效果 ID。资源负责数据，CardEffectRunner 负责实际逻辑。
# - base_cooldown：合法打出这张牌后进入的基础冷却，默认 2 秒。
# - damage_amount：通用伤害数值。A1 范围伤害使用它。
# - enemy_damage_amount：对敌人造成的伤害数值。A2 撞击怪物使用它。
# - body_damage_amount：对肉体造成的伤害数值。B7 击退使用它。
# - move_speed_scale：移动速度倍率。A2 撞击怪物用它临时降低使用者速度。
# - hit_radius：按距离判断“撞到怪物”的半径。A2 使用它检测附近敌人。
# - push_distance：水平推离距离。A4 清场使用它把屏幕内敌人往左推。
# - knockback_distance：击退距离。B7 使用它把屏幕内敌人推离肉体。
# - restore_cards_to_add：恢复生成数量。A5 和 B10 使用它往牌堆加入恢复牌。
# - cooldown_self_multiplier：自身当前冷却倍率。B8 使用它把自己的 CD 翻倍。
# - cooldown_other_multiplier：对方当前冷却倍率。B8 使用它把对方 CD 减半。
# - focused_ally_cooldown：集中火力期间另一位玩家出牌/跳过后的固定 CD。
# - damage_multiplier_base：B12 增伤使用的底数。默认每张手牌让下一次伤害乘以 2。
# - projectile_lifetime：A3 反杀怪物弹道反馈存在时间。
# - has_tag(tag)：返回这张牌是否带有指定词条。
# - to_card_data()：把资源转换成运行时牌堆使用的字典，并复制所有可调数值。

const TAG_CONSUMABLE := "consumable"
const TAG_BREAK_LINK := "break"
const TAG_RESTORE := "restore"

@export var id := ""
@export var card_name := ""
@export var owner_player_id := 0
@export var card_type := "other"
@export var tags := PackedStringArray()
@export_multiline var description := ""
@export var effect_id := ""
@export var base_cooldown := 2.0
@export var damage_amount := 0.0
@export var enemy_damage_amount := 0.0
@export var body_damage_amount := 0.0
@export var move_speed_scale := 1.0
@export var hit_radius := 48.0
@export var push_distance := 0.0
@export var knockback_distance := 0.0
@export var restore_cards_to_add := 0
@export var cooldown_self_multiplier := 1.0
@export var cooldown_other_multiplier := 1.0
@export var focused_ally_cooldown := 0.5
@export var damage_multiplier_base := 2.0
@export var projectile_lifetime := 0.35


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func to_card_data() -> Dictionary:
	return {
		"id": id,
		"name": card_name,
		"owner_player_id": owner_player_id,
		"type": card_type,
		"tags": Array(tags),
		"description": description,
		"effect_id": effect_id,
		"base_cooldown": base_cooldown,
		"damage_amount": damage_amount,
		"enemy_damage_amount": enemy_damage_amount,
		"body_damage_amount": body_damage_amount,
		"move_speed_scale": move_speed_scale,
		"hit_radius": hit_radius,
		"push_distance": push_distance,
		"knockback_distance": knockback_distance,
		"restore_cards_to_add": restore_cards_to_add,
		"cooldown_self_multiplier": cooldown_self_multiplier,
		"cooldown_other_multiplier": cooldown_other_multiplier,
		"focused_ally_cooldown": focused_ally_cooldown,
		"damage_multiplier_base": damage_multiplier_base,
		"projectile_lifetime": projectile_lifetime,
	}
