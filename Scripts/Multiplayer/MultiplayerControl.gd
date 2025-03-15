extends Control

var game_difficulty = 1

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
	var character_selected
	if $InputGroup/CharacterSelect.get_selected_items().size() == 1:
		character_selected = int($InputGroup/CharacterSelect.get_selected_items()[0])
	else:					# If a character is not selected, default to knight
		character_selected = 0
	SendPlayerInfo.rpc_id(1, $InputGroup/LineEdit.text, multiplayer.get_unique_id(), character_selected)

func connection_failed():
	print("Can't connect ")

@rpc("any_peer")
func SendPlayerInfo(name : String, id : int, character_selected : int):
	if !GameManager.GameState.Players.has(id):
		GameManager.GameState.Players[id] = {
			"name" : name,
			"id": id,
			"character" : character_selected
		}
		
		if multiplayer.is_server():
			for i in GameManager.GameState.Players:
				SendPlayerInfo.rpc(GameManager.GameState.Players[i].name, i, GameManager.GameState.Players[i].character)
		
		print(GameManager.GameState)

@rpc("any_peer", "call_local")
func StartGame():
	var scene = load("res://Scenes/GameScene.tscn").instantiate()
	get_tree().root.add_child(scene)
	if multiplayer.is_server():
		scene.host_create_game(game_difficulty)
		print("You are host")
		var json_str = JSON.stringify(GameManager.GameState)
		SendGameState.rpc(json_str)
	else:
		print("You are a client")
	self.hide()

@rpc("any_peer")
func SendGameState(json_state):
	var json = JSON.new()
	var error = json.parse(json_state)
	if error == OK:
		GameManager.GameState = json.data
	else:
		print("Json parse error: ", json.get_error_message())
	$"../GameScene".client_receive_game()

func _on_host_button_down() -> void:
	peer = ENetMultiplayerPeer.new()			# The server
	var error = peer.create_server(port, 4)
	if error != OK:
		print("Can't host: " + error)
		return
	
	# Save on bandwidth usage
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	game_difficulty = int($InputGroup/DifficultyLevel.text)
	
	multiplayer.set_multiplayer_peer(peer)			# Adding the server as a peer
	print("Waiting for Players ")
	var character_selected
	if $InputGroup/CharacterSelect.get_selected_items().size() == 1:
		character_selected = int($InputGroup/CharacterSelect.get_selected_items()[0])
	else:					# If a character is not selected, default to knight
		character_selected = 0
	SendPlayerInfo($InputGroup/LineEdit.text, multiplayer.get_unique_id(), character_selected)

func _on_join_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	
	# Save on bandwidth usage; Same compression
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

func _on_start_button_down() -> void:
	StartGame.rpc()
	pass # Replace with function body.
