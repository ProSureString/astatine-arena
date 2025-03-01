extends Node

class_name GameManager

# Player management
var active_players = []
var player_slots = []
var max_players = 4
var assigned_devices = []

# Camera settings
@export var camera_offset = Vector3(0, 20, 0)
@export var camera_smoothing = 2.0
@export var min_camera_height = 8.5
@export var max_camera_height = 37.5
@export var camera_zoom_margin = 8.5  # Extra space beyond player bounds

# References (is that an undertale reference :ninja_stare:)
@onready var main_camera = $Camera3D
@export var player_scene : PackedScene
@onready var spawn_points = $SpawnPoints.get_children()

# Player joining cooldown to prevent accidental double(oonNnn!)-joins
var join_cooldown = 1.0
var join_timer = 0.0

func _ready():
	player_slots.resize(max_players)
	for i in range(max_players):
		player_slots[i] = null
	
	for i in range(max_players):
		var player = player_scene.instantiate()
		player.visible = false
		add_child(player)
		player.name = "Player" + str(i)
	
	process_join_input(-1)

func _process(delta):
	if join_timer > 0:
		join_timer -= delta
	
	for device_id in Input.get_connected_joypads():
		if !assigned_devices.has(device_id):
			process_join_input(device_id)
	
	if active_players.size() == 0:
		process_join_input(-1)

	
	update_camera(delta)
	
	check_quit_condition()

func process_join_input(device_id):
	if active_players.size() >= max_players:
		return
	
	if join_timer > 0:
		return
		
	var join_pressed = false
	
	if device_id == -1:
		join_pressed = Input.is_action_just_pressed("ui_accept")
	else:
		join_pressed = Input.is_joy_button_pressed(device_id, JOY_BUTTON_START)
	
	if join_pressed:
		for i in range(max_players):
			var player_name = "Player" + str(i)
			var player = get_node_or_null(player_name)
			
			if player and !player.is_active:
				# if the we of ffound an inactive player, activate it
				player.visible = true
				player.global_position = get_spawn_position()
				player.assign_input_device(device_id)
				
				# Add teh newly active thing to active players and mark device as assigned
				active_players.append(player)
				if device_id != -1:  # Only track gamepad devices
					assigned_devices.append(device_id)
					
				# Set join cooldown
				join_timer = join_cooldown
				break

func register_player(player_node, device_id):
	# Find an available player slot
	for i in range(max_players):
		if player_slots[i] == null:
			player_slots[i] = player_node
			return i
	
	# Should never get here if we check max_players before
	return -1

func get_spawn_position():
	if spawn_points.size() == 0:
		return Vector3.ZERO
		
	# Pick a random spawn point (duhh)
	var spawn_index = randi() % spawn_points.size()
	return spawn_points[spawn_index].global_position

func update_camera(delta):
	# Safety check for camera reference
	if !is_instance_valid(main_camera):
		push_error("Main camera not assigned")
		return
		
	if active_players.size() == 0:
		# If no play re, camera goes to center (of map, of scene, whateevr the fu)
		var map_center = Vector3.ZERO #zero cause lazy
		main_camera.global_position = main_camera.global_position.lerp(
			map_center + camera_offset, 
			delta * camera_smoothing
		)
		return
	
	# calculate the averag eposition of all the plaerys
	var avg_pos = Vector3.ZERO
	for player in active_players:
		if is_instance_valid(player):
			avg_pos += player.global_position
	
	# ******Safe****** division with player count ( watch it still divide by zero )
	if active_players.size() > 0:
		avg_pos /= active_players.size()
	
	# calc bound box(idfk how this one works i just yoinked it from a forum)
	var min_pos = Vector3(INF, INF, INF)
	var max_pos = Vector3(-INF, -INF, -INF)

	for player in active_players:
		if is_instance_valid(player):
			min_pos.x = min(min_pos.x, player.global_position.x)
			min_pos.y = min(min_pos.y, player.global_position.y)
			min_pos.z = min(min_pos.z, player.global_position.z)
			
			max_pos.x = max(max_pos.x, player.global_position.x)
			max_pos.y = max(max_pos.y, player.global_position.y)
			max_pos.z = max(max_pos.z, player.global_position.z)
	
	# add margin to the bb
	min_pos.x -= camera_zoom_margin
	min_pos.z -= camera_zoom_margin
	max_pos.x += camera_zoom_margin
	max_pos.z += camera_zoom_margin
	
	# calcluate first for below
	var x_spread = max_pos.x - min_pos.x
	var z_spread = max_pos.z - min_pos.z
	var max_spread = max(x_spread, z_spread)
	
	# adjust cmaera hiehgt pbased on players psread
	var target_height = clamp(
		min_camera_height + max_spread * 0.35,
		min_camera_height,
		max_camera_height
	)
	
	#wowwee aother offset wowww
	var target_offset = Vector3(0, target_height, 0)
	
	# smoothly move camer to targer psostion
	var target_pos = avg_pos + target_offset
	main_camera.global_position = main_camera.global_position.lerp(target_pos, delta * camera_smoothing)

func check_quit_condition():
	# Example: All active players press select/back button together
	var all_pressing_quit = true
	
	for player in active_players:
		var quit_pressed = false
		if player.input_device == -1:
			# Keyboard
			quit_pressed = Input.is_action_pressed("quit")
		else:
			# Gamepad
			quit_pressed = Input.is_joy_button_pressed(player.input_device, JOY_BUTTON_BACK)
		
		if !quit_pressed:
			all_pressing_quit = false
			break
			
	if all_pressing_quit and active_players.size() > 0:
		get_tree().quit()
