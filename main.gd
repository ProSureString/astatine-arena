extends Node3D

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene

func get_random_spawn() -> Vector3:
	var spawns = $Spawns.get_children()
	if spawns.size() > 0:
		return spawns[randi() % spawns.size()].global_transform.origin
	print("nospawns")
	return Vector3(0, 2, 6) # Return default vektohr if there are no children

func _on_host_pressed() -> void:
	peer.create_server(6942)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$CanvasLayer.hide()

func _on_join_pressed() -> void:
	peer.create_client("127.0.0.1", 6942)
	multiplayer.multiplayer_peer = peer
	add_player()
	$CanvasLayer.hide()

func add_player(id = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	var spawn_pos = get_random_spawn()
	add_child(player)
	player.set_multiplayer_authority(id)
	player.global_transform.origin = spawn_pos
	#call_deferred("add_child", player)
	
func del_player(id):
	rpc("_del_player", id)
	
func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

@rpc("any_peer", "call_local")
func _del_player(id):
	get_node(str(id)).queue_free()
