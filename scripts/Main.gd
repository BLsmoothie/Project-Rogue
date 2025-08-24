extends Node2D

func _ready():
	print("Echoes of the Past - Prototype Initialized")
	setup_reference_points()

func _input(event):
	# Handle ascendancy system inputs
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			if MemoryManager.game_completed:
				MemoryManager.start_ascendancy()
		elif event.keycode == KEY_Q:
			if MemoryManager.game_completed:
				print("Thanks for playing Echoes of the Past!")
				get_tree().quit()

func setup_reference_points():
	var points = $ReferencePoints.get_children()
	for point in points:
		if point is Sprite2D:
			var texture = ImageTexture.new()
			var image = Image.create(16, 16, false, Image.FORMAT_RGB8)
			image.fill(point.modulate)
			texture.set_image(image)
			point.texture = texture