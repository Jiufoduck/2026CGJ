extends Sprite2D

@export var speed = 20

func _ready() -> void:
	region_rect.position.x += speed * 5

func _process(delta: float) -> void:
	region_rect.position.x += delta * speed
