class_name GameHUD
extends CanvasLayer

## health_label_path points to the prominent text label that shows exact flesh health.
@export var health_label_path: NodePath = NodePath("Root/HealthLabel")

## health_bar_path points to the prominent progress bar for flesh health.
@export var health_bar_path: NodePath = NodePath("Root/HealthBar")

## link_label_path points to the text label that reports connected, disconnected,
## or game-over link state.
@export var link_label_path: NodePath = NodePath("Root/LinkLabel")

## player_one_card_label_path points to the current-card status label for player one.
@export var player_one_card_label_path: NodePath = NodePath("Root/PlayerOneCard")

## player_two_card_label_path points to the current-card status label for player two.
@export var player_two_card_label_path: NodePath = NodePath("Root/PlayerTwoCard")

## status_label_path points to the general message label for pickups, attacks, and
## win/loss events.
@export var status_label_path: NodePath = NodePath("Root/StatusLabel")

## health_label caches the health text node for frequent updates.
@onready var health_label: Label = get_node(health_label_path) as Label

## health_bar caches the progress bar node for frequent updates.
@onready var health_bar: ProgressBar = get_node(health_bar_path) as ProgressBar

## link_label caches the connection-state text node for frequent updates.
@onready var link_label: Label = get_node(link_label_path) as Label

## player_one_card_label caches player one's deck text node.
@onready var player_one_card_label: Label = get_node(player_one_card_label_path) as Label

## player_two_card_label caches player two's deck text node.
@onready var player_two_card_label: Label = get_node(player_two_card_label_path) as Label

## status_label caches the general status message text node.
@onready var status_label: Label = get_node(status_label_path) as Label


## update_health refreshes the prominent health UI from the authoritative flesh-core
## values supplied by the main controller.
func update_health(current_health: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "肉体血量  %.0f / %.0f" % [current_health, max_health]


## update_connection_state displays whether the link is active or how long remains
## before game over after the link has broken.
func update_connection_state(is_connected: bool, disconnected_time_remaining: float) -> void:
	if is_connected:
		link_label.text = "连线：已连接"
	else:
		link_label.text = "连线：已断开，%.1f 秒后游戏结束" % disconnected_time_remaining


## update_card_panels shows the current top card and cooldown state for both
## independent player card piles. The deck parameters are intentionally untyped so
## the HUD can load before Godot's global class-name cache has been generated.
func update_card_panels(player_one_deck, player_two_deck) -> void:
	player_one_card_label.text = "玩家一：%s" % player_one_deck.get_current_card_label()
	player_two_card_label.text = "玩家二：%s" % player_two_deck.get_current_card_label()


## show_status writes a short gameplay message without owning any gameplay logic.
func show_status(message: String) -> void:
	status_label.text = message
