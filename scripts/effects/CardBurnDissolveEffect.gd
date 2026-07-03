extends Node2D
class_name CardBurnDissolveEffect

# 脚本说明：
# - BurnDissolveShader：卡牌烧洞溶解 shader。它读取 dissolve_texture，并用 dissolve_value 控制烧蚀阈值。
# - TEXTURE_SIZE：白色承载纹理尺寸。纹理只提供稳定 UV。
# - NOISE_TEXTURE_SIZE：每次消耗牌生成的高分辨率随机 NoiseTexture2D 尺寸。
# - card_size：白模卡片尺寸。只影响反馈视觉，不影响 HUD 或牌堆。
# - effect_duration：溶解动画持续时间。
# - burn_size：shader 中烧蚀边缘宽度。数值越大，火边越厚。
# - burn_color：shader 中烧蚀边缘颜色。
# - body_sprite：承载 shader 的白色高分辨率纹理卡片。
# - title_label：显示被消耗的卡牌名称，随主体一起淡出。
# - shader_material：每次播放独立创建的 ShaderMaterial，保证噪声贴图和进度互不干扰。
# - dissolve_texture：本次播放使用的随机 NoiseTexture2D，会传入 shader 的 dissolve_texture。
# - age：效果已播放时间，用于直接驱动 dissolve_value。
# - start_position/end_position：卡片上浮动画的起止位置。
# - finished：是否已经结束，防止重复 queue_free。
# - shared_white_texture：所有实例共用的高分辨率白色纹理。
# - play(card_data, world_position, seed)：在指定世界坐标播放这张牌的烧蚀溶解反馈。
# - _process(delta)：每帧把 dissolve_value 从 1 推到 0、上浮、缩放和文字淡出。
# - _build_card_body()：创建 Sprite2D 卡片主体，让 shader 有稳定 UV。
# - _build_card_label(card_data)：创建卡牌名称标签。
# - _make_dissolve_texture(seed)：创建带随机 seed 的 NoiseTexture2D，并塞进 shader。
# - _get_white_texture()：延迟创建并复用高分辨率白色纹理。

const BurnDissolveShader = preload("res://scripts/effects/card_burn_dissolve.gdshader")
const TEXTURE_SIZE := 1024
const NOISE_TEXTURE_SIZE := 1024

@export var noise:FastNoiseLite
@export var card_size := Vector2(126.0, 172.0)
@export var effect_duration := 1.15
@export var burn_size := 0.085
@export var burn_color := Color(1.0, 0.28, 0.04, 1.0)

static var shared_white_texture: ImageTexture

var body_sprite: Sprite2D
var title_label: Label
var shader_material: ShaderMaterial
var dissolve_texture: NoiseTexture2D
var age := 0.0
var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var finished := false


func play(card_data: Dictionary, world_position: Vector2, seed: float) -> void:
	global_position = world_position
	start_position = position
	end_position = position + Vector2(0.0, -44.0)
	rotation = deg_to_rad(lerpf(-8.0, 8.0, fmod(absf(seed), 1000.0) / 1000.0))
	scale = Vector2.ONE
	_build_card_body()
	_build_card_label(card_data)
	dissolve_texture = _make_dissolve_texture(seed)
	shader_material.set_shader_parameter("dissolve_texture", dissolve_texture)
	shader_material.set_shader_parameter("dissolve_value", 1.0)


func _process(delta: float) -> void:
	if finished:
		return

	age += delta
	var progress: float = clampf(age / maxf(0.001, effect_duration), 0.0, 1.0)
	var eased_progress := progress * progress * (3.0 - 2.0 * progress)
	shader_material.set_shader_parameter("dissolve_value", 1.0 - eased_progress)
	position = start_position.lerp(end_position, sin(progress * PI * 0.5))
	scale = Vector2.ONE.lerp(Vector2(1.08, 1.08), progress)
	if title_label != null:
		title_label.modulate.a = clampf(1.0 - inverse_lerp(0.18, 0.58, progress), 0.0, 1.0)
	if progress >= 1.0:
		finished = true
		queue_free()


func _build_card_body() -> void:
	body_sprite = Sprite2D.new()
	body_sprite.texture = _get_white_texture()
	body_sprite.centered = true
	body_sprite.scale = Vector2(
		card_size.x / float(TEXTURE_SIZE),
		card_size.y / float(TEXTURE_SIZE)
	)
	shader_material = ShaderMaterial.new()
	shader_material.shader = BurnDissolveShader
	body_sprite.material = shader_material
	add_child(body_sprite)


func _build_card_label(card_data: Dictionary) -> void:
	title_label = Label.new()
	title_label.text = str(card_data.get("name", "消耗牌"))
	title_label.custom_minimum_size = Vector2(card_size.x - 16.0, 62.0)
	title_label.size = title_label.custom_minimum_size
	title_label.position = Vector2(-title_label.size.x * 0.5, -title_label.size.y * 0.5)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 19)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.78, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title_label)


func _make_dissolve_texture(seed: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = int(seed)
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.00028
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.35
	noise.fractal_gain = 0.52
	noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE

	var texture := NoiseTexture2D.new()
	texture.width = NOISE_TEXTURE_SIZE
	texture.height = NOISE_TEXTURE_SIZE
	texture.seamless = false
	texture.noise = noise
	return texture


static func _get_white_texture() -> Texture2D:
	if shared_white_texture != null:
		return shared_white_texture

	var image := Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	shared_white_texture = ImageTexture.create_from_image(image)
	return shared_white_texture
