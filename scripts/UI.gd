extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var buff_label: Label = $BuffLabel
var player: Player

func _ready():
	# Find the player in the scene
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node("../Player") as Player
	
	if player:
		setup_health_bar()

func setup_health_bar():
	health_bar.max_value = player.max_health
	health_bar.value = player.current_health

func _process(delta):
	if player:
		update_health_bar()
		update_buff_display()

func update_health_bar():
	health_bar.value = player.current_health
	
	# Change color based on health percentage
	var health_percent = float(player.current_health) / float(player.max_health)
	if health_percent > 0.6:
		health_bar.modulate = Color.GREEN
	elif health_percent > 0.3:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED

func update_buff_display():
	if player.active_buffs.size() > 0:
		var buff_text = ""
		for buff in player.active_buffs:
			var time_left = int(buff.duration)
			buff_text += buff.name + " (" + str(time_left) + "s)\n"
		buff_label.text = buff_text
		buff_label.visible = true
	else:
		buff_label.visible = false