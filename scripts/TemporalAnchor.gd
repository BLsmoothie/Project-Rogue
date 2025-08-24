extends Area2D
class_name TemporalAnchor

func _enter_tree():
	add_to_group("temporal_anchors")

var run_duration: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	setup_visuals()
	# Removed automatic collision-based collection
	# body_entered.connect(_on_body_entered)

func setup_visuals():
	var texture = ImageTexture.new()
	var image = Image.create(24, 24, false, Image.FORMAT_RGB8)
	image.fill(Color.CYAN)
	texture.set_image(image)
	sprite.texture = texture
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	collision_shape.shape = shape

func initialize(duration: float):
	run_duration = duration
	print("=== TEMPORAL ANCHOR CREATED ===")
	print("Position: ", global_position)
	print("Duration: ", run_duration, " seconds")
	
	# Ensure visuals are set up after initialization
	if sprite == null:
		await ready
	print("Visible: ", visible)
	print("Sprite exists: ", sprite != null)

func _on_body_entered(body):
	if body is Player:
		collect_anchor()

func collect_anchor():
	print("=== TEMPORAL ANCHOR COLLECTED ===")
	print("Run duration was: ", run_duration, " seconds")
	
	# Remove from MemoryManager storage so it won't be recreated
	MemoryManager.remove_collected_anchor(global_position)
	
	remove_from_group("temporal_anchors")
	queue_free()
