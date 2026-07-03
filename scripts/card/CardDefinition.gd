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
# - has_tag(tag)：返回这张牌是否带有指定词条。
# - to_card_data()：把资源转换成运行时牌堆使用的字典，并合并子类专属效果数值。
# - get_effect_data()：子类覆盖它，只导出并返回这张牌真正需要的效果参数。

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


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func to_card_data() -> Dictionary:
	var card_data := {
		"id": id,
		"name": card_name,
		"owner_player_id": owner_player_id,
		"type": card_type,
		"tags": Array(tags),
		"description": description,
		"effect_id": effect_id,
		"base_cooldown": base_cooldown,
	}
	card_data.merge(get_effect_data(), true)
	return card_data


func get_effect_data() -> Dictionary:
	return {}
