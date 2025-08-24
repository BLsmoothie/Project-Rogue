extends CharacterBody2D
class_name Enemy

func _enter_tree():
	add_to_group("enemies")

@export var speed: float = 150.0
@export var chase_radius: float = 200.0
@export var max_health: int = 3
@export var damage: int = 1

var current_health: int
var player_reference: Player = null
var is_chasing: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar

func _ready():
	current_health = max_health
	
	# Apply ascendancy scaling if active
	apply_ascendancy_scaling()
	
	setup_enemy_visuals()
	setup_detection_area()
	setup_health_bar()
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta):
	if is_chasing and player_reference:
		chase_player()
	move_and_slide()

func setup_enemy_visuals():
	var texture = ImageTexture.new()
	var image = Image.create(24, 24, false, Image.FORMAT_RGB8)
	image.fill(Color.RED)
	texture.set_image(image)
	sprite.texture = texture
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	$CollisionShape2D.shape = shape

func setup_detection_area():
	var detection_shape_resource = CircleShape2D.new()
	detection_shape_resource.radius = chase_radius
	detection_shape.shape = detection_shape_resource

func setup_health_bar():
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.position = Vector2(-20, -40)  # Above the enemy
	health_bar.size = Vector2(40, 8)
	health_bar.show_percentage = false

func chase_player():
	if not player_reference:
		return
	
	var direction = (player_reference.global_position - global_position).normalized()
	velocity = direction * speed

func _on_detection_area_body_entered(body):
	if body is Player:
		player_reference = body
		is_chasing = true
		print("Enemy started chasing player")

func _on_detection_area_body_exited(body):
	if body is Player:
		is_chasing = false
		velocity = Vector2.ZERO
		print("Enemy stopped chasing player")

func take_damage(amount: int):
	current_health -= amount
	print("Enemy (", name, ") took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	# Update health bar
	health_bar.value = current_health
	
	# Change health bar color based on health
	var health_percent = float(current_health) / float(max_health)
	if health_percent > 0.6:
		health_bar.modulate = Color.GREEN
	elif health_percent > 0.3:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED
	
	# Flash white when taking damage
	sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.RED
	
	if current_health <= 0:
		die()

func die():
	print("Enemy died!")
	queue_free()

func apply_ascendancy_scaling():
	var ascendancy_level = MemoryManager.get_ascendancy_level()
	if ascendancy_level > 0:
		var multiplier = MemoryManager.get_ascendancy_multiplier()
		
		# Scale stats
		max_health = int(max_health * multiplier)
		current_health = max_health
		damage = int(damage * multiplier)
		speed = speed * (1.0 + ascendancy_level * 0.15)  # 15% speed increase per level
		
		print("Enemy scaled for Ascendancy Level ", ascendancy_level, 
			  " - Health: ", max_health, " | Damage: ", damage, " | Speed: ", speed)