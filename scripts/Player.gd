extends CharacterBody2D
class_name Player

@export var speed: float = 300.0
@export var attack_cooldown: float = 0.5

var attack_timer: float = 0.0
var can_attack: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackShape

func _ready():
	setup_player_visuals()
	setup_attack_area()
	MemoryManager.start_new_run()

func _physics_process(delta):
	handle_movement()
	handle_attack(delta)
	move_and_slide()
	
	# Test key - press K to die and test temporal anchor
	if Input.is_action_just_pressed("ui_accept"):
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
	attack_shape_resource.radius = 40
	attack_shape.shape = attack_shape_resource
	attack_area.monitoring = false

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
		velocity = input_vector * speed
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
	
	attack_area.monitoring = true
	var enemies = attack_area.get_overlapping_bodies()
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(1)
			print("Hit enemy: ", enemy.name)
	
	await get_tree().create_timer(0.1).timeout
	attack_area.monitoring = false

func die():
	print("Player died!")
	spawn_temporal_anchor()
	reset_to_new_run()

func spawn_temporal_anchor():
	var run_duration = MemoryManager.end_run()
	var anchor_scene = preload("res://scenes/TemporalAnchor.tscn")
	var anchor = anchor_scene.instantiate()
	anchor.initialize(run_duration)
	anchor.global_position = global_position
	get_tree().current_scene.add_child(anchor)

func reset_to_new_run():
	global_position = Vector2(960, 540)
	MemoryManager.start_new_run()