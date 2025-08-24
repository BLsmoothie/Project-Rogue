extends CharacterBody2D
class_name Boss

func _enter_tree():
	add_to_group("enemies")
	add_to_group("boss")

@export var speed: float = 200.0
@export var max_health: int = 75  # Even more health for highly buffed players
@export var damage: int = 4  # More threatening base damage

var current_health: int
var player_reference: Player = null
var attack_timer: float = 0.0
var attack_cooldown: float = 2.0
var phase: int = 1  # Boss gets stronger as health decreases

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_area: Area2D = $AttackArea

func _ready():
	current_health = max_health
	setup_boss_visuals()
	setup_health_bar()
	setup_attack_area()
	
	print("=== BOSS SPAWNED: FUTURE VILLAIN SELF ===")
	print("Confront your destiny and break the cycle!")

func _physics_process(delta):
	if player_reference:
		boss_ai(delta)
	else:
		find_player()
	move_and_slide()

func setup_boss_visuals():
	# Large dark square representing corrupted future self
	var texture = ImageTexture.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	image.fill(Color(0.2, 0.1, 0.4))  # Dark purple
	texture.set_image(image)
	sprite.texture = texture
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2(64, 64)
	$CollisionShape2D.shape = shape

func setup_health_bar():
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.position = Vector2(-40, -80)  # Above boss
	health_bar.size = Vector2(80, 12)
	health_bar.show_percentage = false
	health_bar.modulate = Color.RED

func setup_attack_area():
	var attack_shape = CircleShape2D.new()
	attack_shape.radius = 100  # Large attack range
	$AttackArea/CollisionShape2D.shape = attack_shape

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_reference = players[0]

func boss_ai(delta):
	attack_timer -= delta
	
	# Determine phase based on health
	var health_percent = float(current_health) / float(max_health)
	if health_percent > 0.66:
		phase = 1
	elif health_percent > 0.33:
		phase = 2
	else:
		phase = 3
	
	# Different behavior per phase
	match phase:
		1:
			phase_1_behavior()
		2:
			phase_2_behavior()  
		3:
			phase_3_behavior()

func phase_1_behavior():
	# Slow, methodical approach
	var direction = (player_reference.global_position - global_position).normalized()
	velocity = direction * speed * 0.7
	
	if attack_timer <= 0 and global_position.distance_to(player_reference.global_position) < 120:
		boss_attack()
		attack_timer = attack_cooldown

func phase_2_behavior():
	# Faster, more aggressive
	var direction = (player_reference.global_position - global_position).normalized()
	velocity = direction * speed
	
	if attack_timer <= 0 and global_position.distance_to(player_reference.global_position) < 140:
		boss_attack()
		attack_timer = attack_cooldown * 0.7  # Faster attacks

func phase_3_behavior():
	# Desperate, erratic movement
	var direction = (player_reference.global_position - global_position).normalized()
	
	# Add some randomness to movement
	direction += Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	direction = direction.normalized()
	
	velocity = direction * speed * 1.3  # Very fast
	
	if attack_timer <= 0 and global_position.distance_to(player_reference.global_position) < 160:
		boss_attack()
		attack_timer = attack_cooldown * 0.5  # Very fast attacks

func boss_attack():
	print("Boss attacks with phase ", phase, " power!")
	
	# Check if player is in range and deal damage
	var overlapping = attack_area.get_overlapping_bodies()
	for body in overlapping:
		if body is Player:
			var phase_damage = damage * phase  # More damage in later phases
			body.take_damage(phase_damage)
			print("Boss dealt ", phase_damage, " damage to player!")
			
			# Visual feedback - flash white
			sprite.modulate = Color.WHITE
			await get_tree().create_timer(0.1).timeout
			sprite.modulate = Color(0.2, 0.1, 0.4)

func take_damage(amount: int):
	current_health -= amount
	print("Boss took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	# Update health bar
	health_bar.value = current_health
	
	# Flash red when taking damage
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(0.2, 0.1, 0.4)
	
	if current_health <= 0:
		die()

func die():
	print("=== BOSS DEFEATED ===")
	print("You have broken the cycle and rewritten your destiny!")
	print("The timeline has been cleansed. Victory!")
	
	# Notify MemoryManager of victory
	MemoryManager.boss_defeated()
	
	show_victory_message()
	queue_free()

func show_victory_message():
	var victory_label = Label.new()
	victory_label.text = "VICTORY!\nYou have defeated your future self!\nThe dark timeline is no more."
	victory_label.add_theme_font_size_override("font_size", 48)
	victory_label.add_theme_color_override("font_color", Color.GOLD)
	
	var viewport_size = get_viewport().get_visible_rect().size
	victory_label.position = Vector2(viewport_size.x/2 - 300, viewport_size.y/2 - 100)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(victory_label)

func apply_ascendancy_scaling(ascendancy_level: int):
	var multiplier = 1.0 + (ascendancy_level * 0.5)  # 50% increase per level
	
	# Scale stats
	max_health = int(max_health * multiplier)
	current_health = max_health
	damage = int(damage * multiplier)
	speed = speed * (1.0 + ascendancy_level * 0.2)  # 20% speed increase per level
	
	# Update health bar
	setup_health_bar()
	
	# Visual indicator of enhanced boss
	sprite.modulate = Color(0.2 + ascendancy_level * 0.1, 0.1, 0.4 + ascendancy_level * 0.1)
	
	print("Boss enhanced for Ascendancy Level ", ascendancy_level)
	print("Health: ", max_health, " | Damage: ", damage, " | Speed: ", speed)