extends Node3D

# This script manages the main game scene

@onready var game_manager = $GameManager
@onready var player_container = $Players
#@onready var UI = $UI

# UI text for instructions
#@onready var instructions_label = $UI/Instructions

func _ready():
	# Initialize instructions
	update_instructions()
	
	# Connect to player join signal
	for i in range(game_manager.max_players):
		var player = get_node("GameManager/Player" + str(i))
		if player:
			player.player_joined.connect(_on_player_joined)

func _process(delta):
	# Update player count display
	update_instructions()

func update_instructions():
	var active_count = game_manager.active_players.size()
	var max_count = game_manager.max_players
	
	if active_count < max_count:
		print("Players: " + str(active_count) + "/" + str(max_count) + "\n")
		print("Press START on gamepad or ENTER on keyboard to join!")
		#instructions_label.text = "Players: " + str(active_count) + "/" + str(max_count) + "\n"
		#instructions_label.text += "Press START on gamepad or ENTER on keyboard to join!"
	else:
		#instructions_label.text = "Maximum players reached (" + str(max_count) + ")"
		print("Maximum players reached (" + str(max_count) + ")")

func _on_player_joined(player_node, device_id):
	# Visual feedback when a player joins
	var player_index = game_manager.player_slots.find(player_node)
	if player_index >= 0:
		# Show a quick message
		#var join_label = Label.new()
		#join_label.text = "Player " + str(player_index + 1) + " joined!"
		
		if device_id == -1:
			#join_label.text += " (Keyboard)"
			print("Player " + str(player_index + 1) + " joined!" + " (Keyboard)")
		else:
			print("Player " + str(player_index + 1) + " joined!" + " (Gamepad " + str(device_id) + ")")
			#join_label.text += " (Gamepad " + str(device_id) + ")"
		
		#UI.add_child(join_label)
		
		# Position based on player index
		#join_label.position = Vector2(50, 100 + player_index * 30)
		
		# Animate and remove after a few seconds
		#var tween = create_tween()
		#tween.tween_property(join_label, "modulate:a", 0.0, 2.0).set_delay(1.0)
		#tween.tween_callback(join_label.queue_free)
