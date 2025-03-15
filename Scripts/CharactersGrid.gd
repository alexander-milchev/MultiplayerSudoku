extends Node2D

@onready var boardFrontend = $"../.."
@onready var tileMaps = $".."
@onready var cellDirtLayer = $"../CellDirtLayer"
@onready var selectHighlight = $"../CharacterLayerHL"
@onready var selectedCharacter = $"../CharacterLayerSelect"

var enemyBehaviours : EnemyBehaviours		# Will store behaviours of all enemies. Created only by the server for now
# though this assumes the host will be the server until the end of the game and nobody else can become the authority

var charactersPos : Array				# Character positions. Null if not occupied by a character
var characters : Array					# List of Characters in the game, ordered by turn order. Potentially all allies then all enemies in order.
var ownedCharacterIndex = 0				# Index in the characters array of character owned by player
var currentTurnCharacter = -1			# Index of character currently taking turn

func init_grid(dimensions : int, chars : Array, starts : Array):
	charactersPos = _initMatrix(dimensions, dimensions)
	characters = chars
	_placeChars(starts)
	if multiplayer.is_server():
		enemyBehaviours = EnemyBehaviours.new(self, tileMaps, cellDirtLayer)
	
func _initMatrix(cols : int, rows : int):
	var outp = []
	outp.resize(cols)
	for i in range(cols):
		outp[i] = []
		outp[i].resize(rows)
		outp[i].fill(null)
		for j in range(rows):
			var grid_pos = Node2D.new()
			grid_pos.name = "GridPosition" + str(i) + str(j)
			grid_pos.position = Vector2(32*i, 32*j)
			add_child(grid_pos)
	return outp

func _placeChars(positions : Array):
	for i in range(characters.size()):
		var loc = getGridPoint(positions[i][0], positions[i][1])
		add_child(characters[i])
		characters[i].global_position = loc.global_position
		charactersPos[positions[i][0]][positions[i][1]] = characters[i]

func getGridPoint(col : int, row : int):
	return get_child(charactersPos.size() * col + row)

func getPosition(unit : CharacterBase):
	if unit in characters:
		for i in range (charactersPos.size()):
			for j in range (charactersPos[i].size()):
				if charactersPos[i][j] == unit:
					return Vector2i(i, j)
	else:
		print(characters, unit)
		return Vector2i(-1, -1)

func getValidNeighbours(col : int, row : int):
	var outputs: Array = []
	if col - 1 >= 0:							# Left
		if charactersPos[col - 1][row] == null or charactersPos[col - 1][row] == characters[currentTurnCharacter]:
			outputs.append(["Left", col - 1, row])
	if row - 1 >= 0:							# Up
		if charactersPos[col][row - 1] == null or charactersPos[col][row - 1] == characters[currentTurnCharacter]:
			outputs.append(["Up", col, row - 1])
	if col + 1 < charactersPos.size():			# Right
		if charactersPos[col + 1][row] == null or charactersPos[col + 1][row] == characters[currentTurnCharacter]:
			outputs.append(["Right", col + 1, row])
	if row + 1 < charactersPos[col].size():		# Down
		if charactersPos[col][row + 1] == null or charactersPos[col][row + 1] == characters[currentTurnCharacter]:
			outputs.append(["Down", col, row + 1])
	return outputs

@rpc("any_peer", "call_local")
func moveCharacter(unit_idx : int, movements : Array):
	var unitPos = getPosition(characters[unit_idx])
	var newPos = movements[-1]								# Move to the end of the movements for now
	charactersPos[unitPos[0]][unitPos[1]] = null			# Update the start position to empty
	characters[unit_idx].global_position = getGridPoint(newPos[0], newPos[1]).global_position			# Move visual element to the new grid point
	charactersPos[newPos[0]][newPos[1]] = characters[unit_idx]				# Update with the new position
	# for movement in movements:							# Animate Movement
	# 	pass

func getDistance(start : Vector2i, target : Vector2i):
	var x_dist = abs(start.x - target.x)
	var y_dist = abs(start.y - target.y)
	return x_dist + y_dist

func displayReachFromOwner():
	displayReach(getPosition(characters[ownedCharacterIndex]))

func displayReach(pos : Vector2i):
	var reach = characters[ownedCharacterIndex].reach
	for col in range(charactersPos.size()):
		for row in range(charactersPos[col].size()):
			if getDistance(pos, Vector2i(col, row)) <= reach:
				selectHighlight.set_cell(Vector2i(col, row), 1, Vector2i(0, 0))

@rpc("any_peer", "call_local")
func damageUnit(pos : Vector2i, dmg : int):
	var damaged = charactersPos[pos.x][pos.y]
	damaged.health -= dmg
	print("Unit Damaged! ", damaged.name, " is at ", damaged.health, " HP!")
	if damaged.health <= 0:
		for idx in range(characters.size(), 0, -1):
			if characters[idx - 1] == damaged and getPosition(characters[idx - 1]) == pos:
				killCharacter(idx - 1)

# Turn based system
@rpc("any_peer", "call_local")
func advanceTurnOrder():
	currentTurnCharacter += 1
	if currentTurnCharacter >= characters.size():
		currentTurnCharacter = 0					# Loop back to the first character
	print(currentTurnCharacter, " now taking turn. ", multiplayer.get_unique_id())
	if ownedCharacterIndex == currentTurnCharacter:
		boardFrontend.prepareTurn()
	else:
		await get_tree().create_timer(3.0).timeout
		# Only let the server run enemy decisions, only rpc the actions the enemies take.
		if multiplayer.is_server() and characters[currentTurnCharacter].playerID == null:
			enemyBehaviours.performEnemyTurnWithBehaviour(characters[currentTurnCharacter].bhvr, currentTurnCharacter)
		

func killCharacter(char_idx : int):
	# print("Killed ", char_idx, " for ", multiplayer.get_unique_id())
	var pos = getPosition(characters[char_idx])
	charactersPos[pos[0]][pos[1]] = null				# Empty their grid space
	characters[char_idx].visible = false				# Turn off their visual
	characters.remove_at(char_idx)						# Remove them from tracking
	if char_idx <= currentTurnCharacter:		# If the character that died is having a turn right now or earlier
		currentTurnCharacter -= 1				# Push back current turn by 1, as next character is pushed back by 1 in index

func wait(sec : float):
	await get_tree().create_timer(sec).timeout
	return
