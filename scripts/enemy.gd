class_name Enemy
extends CharacterBody3D

## EnemyKind lists the three editable enemy categories requested by the design
## document. Their deeper AI can be replaced later without changing scene ownership.
enum EnemyKind {
	SCOUT,
	GUARD,
	BRUTE,
}

## enemy_kind identifies which of the three enemy types this scene instance represents.
@export var enemy_kind: EnemyKind = EnemyKind.SCOUT

## max_health is this enemy's starting and maximum health value for card damage.
@export var max_health: float = 40.0

## contact_damage is the amount of flesh-core damage dealt when the enemy's attack
## area touches the center hit point.
@export var contact_damage: float = 10.0

## placeholder_patrol_enabled allows designers to preview enemy collision against
## scene walls before the final enemy AI is implemented.
@export var placeholder_patrol_enabled: bool = false

## placeholder_patrol_direction is the local X/Z direction used by the temporary
## patrol behavior when placeholder_patrol_enabled is true.
@export var placeholder_patrol_direction: Vector3 = Vector3.LEFT

## placeholder_patrol_speed is the temporary movement speed used only by the simple
## pre-AI patrol preview.
@export var placeholder_patrol_speed: float = 2.0

## attack_area_path points to the child Area3D that detects the flesh core without
## making enemies collide with player-only camera blockers.
@export var attack_area_path: NodePath = NodePath("AttackArea")

## current_health stores this enemy's live health after player attack cards hit it.
var current_health: float = 40.0

## attack_area caches the child Area3D used for contact damage.
@onready var attack_area: Area3D = get_node_or_null(attack_area_path) as Area3D


## _ready initializes health, registers the scene as an enemy for card targeting,
## and connects the contact damage area if present.
func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	if is_instance_valid(attack_area):
		attack_area.body_entered.connect(_on_attack_area_body_entered)


## _physics_process runs only the optional placeholder patrol; final enemy AI is
## intentionally left for the later implementation pass named in the document.
func _physics_process(_delta: float) -> void:
	if not placeholder_patrol_enabled:
		return

	var movement_direction: Vector3 = placeholder_patrol_direction
	movement_direction.y = 0.0
	velocity = movement_direction.normalized() * placeholder_patrol_speed
	move_and_slide()


## take_damage subtracts card damage from the enemy and removes the enemy when its
## health reaches zero.
func take_damage(amount: float) -> void:
	current_health = maxf(current_health - amount, 0.0)
	if current_health <= 0.0:
		queue_free()


## is_alive reports whether this enemy can still be targeted by attack cards.
func is_alive() -> bool:
	return current_health > 0.0 and not is_queued_for_deletion()


## _on_attack_area_body_entered damages the flesh core when the contact area touches
## it, while ignoring players and camera-bound collision bodies.
func _on_attack_area_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.call("take_damage", contact_damage)
