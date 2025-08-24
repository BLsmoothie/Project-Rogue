extends Node2D
class_name DungeonGenerator

@export var room_count: int = 5
@export var room_size_min: Vector2 = Vector2(200, 200)
@export var room_size_max: Vector2 = Vector2(400, 400)
@export var corridor_width: int = 64

var rooms: Array[Rect2] = []
var enemy_scene = preload("res://scenes/Enemy.tscn")

func _ready():
	generate_dungeon()

func generate_dungeon():
	print("Generating dungeon...")
	generate_rooms()
	spawn_enemies()
	draw_dungeon_walls()

func generate_rooms():
	for i in room_count:
		var room_size = Vector2(
			randf_range(room_size_min.x, room_size_max.x),
			randf_range(room_size_min.y, room_size_max.y)
		)
		
		var room_pos = Vector2(
			randf_range(0, 2000 - room_size.x),
			randf_range(0, 1500 - room_size.y)
		)
		
		var room = Rect2(room_pos, room_size)
		rooms.append(room)
		
		print("Generated room ", i + 1, ": ", room)

func spawn_enemies():
	for i in range(rooms.size()):
		var room = rooms[i]
		
		if i == 0:
			continue
		
		var enemy_count = randi_range(1, 3)
		for j in enemy_count:
			var enemy = enemy_scene.instantiate()
			
			var spawn_pos = Vector2(
				randf_range(room.position.x + 50, room.position.x + room.size.x - 50),
				randf_range(room.position.y + 50, room.position.y + room.size.y - 50)
			)
			
			enemy.global_position = spawn_pos
			add_child(enemy)
			print("Spawned enemy at: ", spawn_pos)

func draw_dungeon_walls():
	for room in rooms:
		create_room_walls(room)

func create_room_walls(room: Rect2):
	var wall_thickness = 20
	var wall_color = Color.GRAY
	var doorway_size = 80
	
	# Top wall with doorway
	var top_left = Rect2(room.position.x - wall_thickness, room.position.y - wall_thickness, (room.size.x - doorway_size) / 2, wall_thickness)
	var top_right = Rect2(room.position.x + (room.size.x + doorway_size) / 2, room.position.y - wall_thickness, (room.size.x - doorway_size) / 2 + wall_thickness, wall_thickness)
	
	# Bottom wall with doorway  
	var bottom_left = Rect2(room.position.x - wall_thickness, room.position.y + room.size.y, (room.size.x - doorway_size) / 2, wall_thickness)
	var bottom_right = Rect2(room.position.x + (room.size.x + doorway_size) / 2, room.position.y + room.size.y, (room.size.x - doorway_size) / 2 + wall_thickness, wall_thickness)
	
	# Left wall with doorway
	var left_top = Rect2(room.position.x - wall_thickness, room.position.y - wall_thickness, wall_thickness, (room.size.y - doorway_size) / 2)
	var left_bottom = Rect2(room.position.x - wall_thickness, room.position.y + (room.size.y + doorway_size) / 2, wall_thickness, (room.size.y - doorway_size) / 2 + wall_thickness)
	
	# Right wall with doorway
	var right_top = Rect2(room.position.x + room.size.x, room.position.y - wall_thickness, wall_thickness, (room.size.y - doorway_size) / 2)
	var right_bottom = Rect2(room.position.x + room.size.x, room.position.y + (room.size.y + doorway_size) / 2, wall_thickness, (room.size.y - doorway_size) / 2 + wall_thickness)
	
	var wall_segments = [top_left, top_right, bottom_left, bottom_right, left_top, left_bottom, right_top, right_bottom]
	
	for wall in wall_segments:
		if wall.size.x > 0 and wall.size.y > 0:
			var wall_sprite = Sprite2D.new()
			var texture = ImageTexture.new()
			var image = Image.create(int(wall.size.x), int(wall.size.y), false, Image.FORMAT_RGB8)
			image.fill(wall_color)
			texture.set_image(image)
			wall_sprite.texture = texture
			wall_sprite.position = Vector2(wall.position.x + wall.size.x/2, wall.position.y + wall.size.y/2)
			add_child(wall_sprite)