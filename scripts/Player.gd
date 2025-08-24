extends CharacterBody2D
class_name Player

# Add player to a group so UI can find it
func _enter_tree():
	add_to_group("player")

@export var speed: float = 300.0
@export var attack_cooldown: float = 0.5
@export var max_health: int = 5

var attack_timer: float = 0.0
var can_attack: bool = true
var current_health: int
var is_dead: bool = false

# Power-up system
var base_speed: float = 300.0
var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var active_buffs: Array[Dictionary] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/AttackShape
@onready var attack_indicator: Sprite2D = $AttackIndicator

func _ready():
	current_health = max_health
	base_speed = speed
	setup_player_visuals()
	setup_attack_area()
	MemoryManager.start_new_run()

func _physics_process(delta):
	if not is_dead:
		update_buffs(delta)
		handle_movement()
		handle_attack(delta)
		move_and_slide()
		check_enemy_collisions()
		
		# Test key - press T to die and test temporal anchor
		if Input.is_physical_key_pressed(KEY_T):
			die()

func setup_player_visuals():
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.GREEN)
	texture.set_image(image)
	sprite.texture = texture
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	$CollisionShape2D.shape = shape

func setup_attack_area():
	var attack_shape_resource = CircleShape2D.new()
	attack_shape_resource.radius = 160  # Doubled again from 80
	attack_shape.shape = attack_shape_resource
	attack_area.monitoring = false
	
	# Setup attack indicator
	var indicator_texture = ImageTexture.new()
	var indicator_image = Image.create(320, 320, false, Image.FORMAT_RGBA8)  # Doubled from 160x160
	indicator_image.fill(Color(1, 1, 0, 0.3))  # Semi-transparent yellow
	indicator_texture.set_image(indicator_image)
	attack_indicator.texture = indicator_texture
	attack_indicator.visible = false

func handle_movement():
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		velocity = input_vector * (base_speed * speed_multiplier)
	else:
		velocity = Vector2.ZERO

func handle_attack(delta):
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	if Input.is_action_just_pressed("attack") and can_attack:
		perform_attack()

func perform_attack():
	can_attack = false
	attack_timer = attack_cooldown
	
	# Show attack indicator
	attack_indicator.visible = true
	
	# Get all enemies and check distance
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= 160:  # Attack range
			if enemy.has_method("take_damage"):
				var damage = int(1 * damage_multiplier)
				enemy.take_damage(damage)
				show_damage_number(enemy.global_position, damage)
	
	# Also check for temporal anchors in attack range
	var all_anchors = get_tree().get_nodes_in_group("temporal_anchors")
	for anchor in all_anchors:
		var distance = global_position.distance_to(anchor.global_position)
		if distance <= 160:  # Same attack range
			print("Collecting anchor via attack!")
			apply_anchor_powerup(anchor.run_duration)
			anchor.collect_anchor()
	
	await get_tree().create_timer(0.2).timeout
	attack_indicator.visible = false

func die():
	if is_dead:
		return
		
	is_dead = true
	print("Player died!")
	
	# Make player invisible and stop movement
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)  # Semi-transparent gray
	velocity = Vector2.ZERO
	
	# Disable collision detection to prevent anchor collection
	$CollisionShape2D.disabled = true
	
	# Spawn anchor immediately at death position
	spawn_temporal_anchor()
	
	# Show respawn timer
	show_respawn_timer()
	
	# Wait 5 seconds, then respawn
	await get_tree().create_timer(5.0).timeout
	reset_to_new_run()

func spawn_temporal_anchor():
	var run_duration = MemoryManager.end_run()
	
	print("=== SPAWNING ANCHOR ===")
	print("Death position: ", global_position)
	
	# Store anchor data in MemoryManager instead of creating object
	MemoryManager.store_anchor_data(global_position, run_duration)

func check_enemy_collisions():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is Enemy:
			take_damage(1)

func take_damage(amount: int):
	current_health -= amount
	print("Player took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	# Flash red when taking damage
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.GREEN
	
	if current_health <= 0:
		die()

func reset_to_new_run():
	print("=== RESPAWNING PLAYER ===")
	
	is_dead = false
	current_health = max_health
	sprite.modulate = Color.GREEN  # Restore normal color
	$CollisionShape2D.disabled = false  # Re-enable collision
	global_position = Vector2(100, 100)  # Far from typical death locations
	MemoryManager.start_new_run()
	
	# Wait a frame before recreating anchors to ensure player position is set
	await get_tree().process_frame
	MemoryManager.recreate_anchors_in_scene()

func show_damage_number(pos: Vector2, damage: int):
	var damage_label = Label.new()
	damage_label.text = str(damage)
	damage_label.add_theme_font_size_override("font_size", 48)
	damage_label.add_theme_color_override("font_color", Color.RED)
	damage_label.position = pos
	damage_label.z_index = 100
	get_tree().current_scene.add_child(damage_label)
	
	# Animate the damage number
	var tween = create_tween()
	tween.parallel().tween_property(damage_label, "position", damage_label.position + Vector2(0, -100), 2.0)
	tween.parallel().tween_property(damage_label, "modulate", Color.TRANSPARENT, 2.0)
	tween.tween_callback(damage_label.queue_free)

func show_respawn_timer():
	# Create a respawn timer label in the center of the screen
	var timer_label = Label.new()
	timer_label.text = "RESPAWNING IN 5"
	timer_label.add_theme_font_size_override("font_size", 64)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Center it on screen (camera follows player, so use screen center)
	var viewport_size = get_viewport().get_visible_rect().size
	timer_label.position = Vector2(viewport_size.x/2 - 200, viewport_size.y/2 - 32)
	timer_label.z_index = 200
	
	# Add to a CanvasLayer so it stays on screen
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(timer_label)
	
	# Countdown from 5 to 1
	for i in range(5):
		timer_label.text = "RESPAWNING IN " + str(5 - i)
		await get_tree().create_timer(1.0).timeout
	
	# Clean up
	canvas.queue_free()

func update_buffs(delta):
	# Update all active buffs, remove expired ones
	for i in range(active_buffs.size() - 1, -1, -1):
		active_buffs[i].duration -= delta
		if active_buffs[i].duration <= 0:
			remove_buff(active_buffs[i])
			active_buffs.remove_at(i)

func apply_anchor_powerup(run_duration: float):
	var buff_duration = 30.0  # All buffs last 30 seconds
	
	if run_duration < 10.0:
		# Short run: Speed boost only
		add_buff("speed", 1.5, buff_duration, "Echo Boost")
		print("Applied ECHO BOOST: +50% speed for 30 seconds")
		
	elif run_duration < 30.0:
		# Medium run: Speed + damage
		add_buff("speed", 1.8, buff_duration, "Memory Surge")  
		add_buff("damage", 2.0, buff_duration, "Memory Surge")
		print("Applied MEMORY SURGE: +80% speed, +100% damage for 30 seconds")
		
	else:
		# Long run: Speed + damage + health
		add_buff("speed", 2.0, buff_duration, "Temporal Mastery")
		add_buff("damage", 3.0, buff_duration, "Temporal Mastery") 
		add_buff("health", 2, buff_duration, "Temporal Mastery")
		print("Applied TEMPORAL MASTERY: +100% speed, +200% damage, +2 health for 30 seconds")

func add_buff(type: String, value: float, duration: float, name: String):
	var buff = {
		"type": type,
		"value": value,
		"duration": duration,
		"name": name
	}
	
	active_buffs.append(buff)
	apply_buff(buff)

func apply_buff(buff: Dictionary):
	match buff.type:
		"speed":
			speed_multiplier *= buff.value
		"damage":
			damage_multiplier *= buff.value
		"health":
			current_health += int(buff.value)
			if current_health > max_health + 5:  # Cap bonus health
				current_health = max_health + 5

func remove_buff(buff: Dictionary):
	match buff.type:
		"speed":
			speed_multiplier /= buff.value
		"damage":  
			damage_multiplier /= buff.value
		"health":
			# Health buffs don't get removed when expired
			pass
	
	print("Buff expired: ", buff.name)
