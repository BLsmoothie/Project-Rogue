extends Node

signal player_died(run_duration: float)

var global_timer: float = 0.0
var is_run_active: bool = true

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

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