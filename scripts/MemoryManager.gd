extends Node

signal player_died(run_duration: float)

var global_timer: float = 0.0
var is_run_active: bool = true
var anchor_container: Node2D
var stored_anchors: Array[Dictionary] = []

# Boss spawn tracking
var total_anchors_collected: int = 0
var boss_spawned: bool = false
var boss_spawn_threshold: int = 3  # Spawn boss after collecting 3 anchors

# Ascendancy System
var ascendancy_level: int = 0
var total_victories: int = 0
var game_completed: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create a persistent container for anchors
	anchor_container = Node2D.new()
	anchor_container.name = "TemporalAnchors"
	get_tree().current_scene.add_child(anchor_container)
	
	print("MemoryManager initialized - Ascendancy Level: ", ascendancy_level)

func _process(delta):
	if is_run_active:
		global_timer += delta

func start_new_run():
	global_timer = 0.0
	is_run_active = true
	print("New run started")

func end_run():
	is_run_active = false
	var final_duration = global_timer
	print("Run ended. Duration: ", final_duration, " seconds")
	player_died.emit(final_duration)
	return final_duration

func get_current_run_time() -> float:
	return global_timer

func store_anchor_data(position: Vector2, duration: float):
	var anchor_data = {
		"position": position,
		"duration": duration
	}
	stored_anchors.append(anchor_data)
	print("Stored anchor data: position=", position, " duration=", duration)

func recreate_anchors_in_scene():
	print("Recreating ", stored_anchors.size(), " anchors")
	var anchor_scene = preload("res://scenes/TemporalAnchor.tscn")
	
	for anchor_data in stored_anchors:
		var anchor = anchor_scene.instantiate()
		anchor.global_position = anchor_data.position
		get_tree().current_scene.add_child(anchor)
		anchor.initialize(anchor_data.duration)
		print("Recreated anchor at ", anchor_data.position)

func remove_collected_anchor(position: Vector2):
	for i in range(stored_anchors.size()):
		if stored_anchors[i].position.distance_to(position) < 50:  # Close enough
			stored_anchors.remove_at(i)
			total_anchors_collected += 1
			print("Removed collected anchor from storage. Total collected: ", total_anchors_collected)
			
			# Check if boss should spawn
			check_boss_spawn()
			break

func check_boss_spawn():
	if not boss_spawned and total_anchors_collected >= boss_spawn_threshold:
		boss_spawned = true
		spawn_boss()

func spawn_boss():
	print("=== BOSS SPAWN CONDITIONS MET ===")
	if ascendancy_level > 0:
		print("Ascendancy Level ", ascendancy_level, " - Enhanced Boss!")
	print("Your future self emerges from the depths of corrupted memory...")
	
	# Show dramatic message
	show_boss_arrival_message()
	
	# Wait a moment for drama
	await get_tree().create_timer(3.0).timeout
	
	var boss_scene = preload("res://scenes/Boss.tscn")
	var boss = boss_scene.instantiate()
	
	# Apply ascendancy scaling to boss
	if ascendancy_level > 0:
		boss.apply_ascendancy_scaling(ascendancy_level)
	
	# Spawn boss in the center of the world, away from player spawn
	boss.global_position = Vector2(1500, 800)  # Central area
	get_tree().current_scene.add_child(boss)
	
	print("Boss spawned at: ", boss.global_position)

func show_boss_arrival_message():
	var message_label = Label.new()
	message_label.text = "The memories converge...\nYour future self stirs in the darkness...\nPrepare for the final confrontation!"
	message_label.add_theme_font_size_override("font_size", 32)
	message_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	
	var viewport_size = get_tree().current_scene.get_viewport().get_visible_rect().size
	message_label.position = Vector2(viewport_size.x/2 - 250, viewport_size.y/2 - 60)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 150
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(message_label)
	
	# Fade out after 3 seconds
	await get_tree().create_timer(3.0).timeout
	canvas.queue_free()

# Ascendancy System Functions
func boss_defeated():
	total_victories += 1
	game_completed = true
	
	print("=== VICTORY ACHIEVED ===")
	print("Total Victories: ", total_victories)
	
	if total_victories == 1:
		print("=== ASCENDANCY SYSTEM UNLOCKED ===")
		print("You can now continue with increased difficulty!")
		show_ascendancy_unlock()
	else:
		print("Ascendancy Level ", ascendancy_level, " completed!")
		show_continue_option()

func show_ascendancy_unlock():
	var unlock_label = Label.new()
	unlock_label.text = "ASCENDANCY UNLOCKED!\nPress R to continue with increased difficulty\nPress Q to quit"
	unlock_label.add_theme_font_size_override("font_size", 32)
	unlock_label.add_theme_color_override("font_color", Color.CYAN)
	
	var viewport_size = get_tree().current_scene.get_viewport().get_visible_rect().size
	unlock_label.position = Vector2(viewport_size.x/2 - 250, viewport_size.y/2 + 100)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 201
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(unlock_label)

func show_continue_option():
	var continue_label = Label.new()
	continue_label.text = "Press R to continue Ascendancy Level " + str(ascendancy_level + 1) + "\nPress Q to quit"
	continue_label.add_theme_font_size_override("font_size", 32)
	continue_label.add_theme_color_override("font_color", Color.YELLOW)
	
	var viewport_size = get_tree().current_scene.get_viewport().get_visible_rect().size
	continue_label.position = Vector2(viewport_size.x/2 - 200, viewport_size.y/2 + 100)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 201
	get_tree().current_scene.add_child(canvas)
	canvas.add_child(continue_label)

func start_ascendancy():
	if game_completed:
		ascendancy_level += 1
		print("=== ASCENDING TO LEVEL ", ascendancy_level, " ===")
		print("Enemies will be ", get_ascendancy_multiplier(), "x stronger!")
		restart_game()

func restart_game():
	# Reset game state but keep ascendancy progress
	stored_anchors.clear()
	total_anchors_collected = 0
	boss_spawned = false
	game_completed = false
	start_new_run()
	
	# Reload the main scene
	get_tree().reload_current_scene()

func get_ascendancy_multiplier() -> float:
	return 1.0 + (ascendancy_level * 0.5)  # 50% increase per level

func get_ascendancy_level() -> int:
	return ascendancy_level