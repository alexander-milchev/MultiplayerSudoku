extends Node2D

@onready var boardFrontend = $"../.."

var charactersPos				# Character positions. Null if not occupied by a character
var characters					# List of Characters in the game, ordered by turn order. Potentially all allies then all enemies.
var currentActiveCharacter		# Index of current active character? Update in turn order

func init_grid(dimensions : int, chars : Array, starts : Array):
	charactersPos = _initMatrix(dimensions, dimensions)
	characters = chars
	_placeChars(starts)
	currentActiveCharacter = 0
	
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
		if charactersPos[col - 1][row] == null or charactersPos[col - 1][row] == characters[currentActiveCharacter]:
			outputs.append(["Left", col - 1, row])
	if row - 1 >= 0:							# Up
		if charactersPos[col][row - 1] == null or charactersPos[col][row - 1] == characters[currentActiveCharacter]:
			outputs.append(["Up", col, row - 1])
	if col + 1 < charactersPos.size():			# Right
		if charactersPos[col + 1][row] == null or charactersPos[col + 1][row] == characters[currentActiveCharacter]:
			outputs.append(["Right", col + 1, row])
	if row + 1 < charactersPos[col].size():		# Down
		if charactersPos[col][row + 1] == null or charactersPos[col][row + 1] == characters[currentActiveCharacter]:
			outputs.append(["Down", col, row + 1])
	return outputs

func moveCharacter(unit : CharacterBase, movements : Array):
	var unitPos = getPosition(unit)
	var newPos = movements[-1]
	charactersPos[unitPos[0]][unitPos[1]] = null
	unit.global_position = getGridPoint(newPos[0], newPos[1]).global_position
	charactersPos[newPos[0]][newPos[1]] = unit
	boardFrontend.movementMode()
	# for movement in movements:
	# 	pass
