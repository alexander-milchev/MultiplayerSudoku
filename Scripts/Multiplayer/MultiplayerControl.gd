extends Control

@export var Address = "127.0.0.1"
@export var port = 8910
var peer

func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

# Called on server and clients whenever someone connects
func peer_connected(id):
	print("Player connected " + str(id))

func peer_disconnected(id):
	print("Player disconnected " + str(id))

# Called only by clients
func connected_to_server():
	print("Connected to Server! ")
	SendPlayerInfo.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())

func connection_failed():
	print("Can't connect ")

@rpc("any_peer")
func SendPlayerInfo(name : String, id : int):
	if !GameManager.Players.has(id):
		GameManager.Players[id] = {
			"name" : name,
			"id": id,
		}
		
		if multiplayer.is_server():
			for i in GameManager.Players:
				SendPlayerInfo.rpc(GameManager.Players[i].name, i)

@rpc("any_peer", "call_local")
func StartGame():
	var scene = load("res://Scenes/GameScene.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func _on_host_button_down() -> void:
	peer = ENetMultiplayerPeer.new()			# The server
	var error = peer.create_server(port, 2)
	if error != OK:
		print("Can't host: " + error)
		return
	
	# Save on bandwidth usage
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)			# Adding the server as a peer
	print("Waiting for Players ")
	
	SendPlayerInfo($LineEdit.text, multiplayer.get_unique_id())
	
	pass # Replace with function body.


func _on_join_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	
	# Save on bandwidth usage; Same compression
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	pass # Replace with function body.


func _on_start_button_down() -> void:
	StartGame.rpc()
	pass # Replace with function body.
