extends TileMapLayer

@onready var boardFrontend = $"../.."

var charactersPos				# Character positions. Null if not occupied by a character
var characters					# List of Characters in the game, ordered by turn order. Potentially all allies then all enemies.
var currentActiveCharacter		# Index of current active character? Update in turn order

func init_layer(dimensions : int, chars : Array, starts : Array):
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
	return outp

func _placeChars(positions : Array):
	for i in range(characters.size()):
		set_cell(positions[i], characters[i].sprite_id, Vector2i(0, 0))
		charactersPos[positions[i][0]][positions[i][1]] = characters[i]

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

# Passing the character to move and the list of movements to follow. Movements are formatted as [Vector2i(i, j)]
func moveCharacter(unit : CharacterBase, movements : Array):
	var unitPos = getPosition(unit)
	var newPos = movements[-1]
	erase_cell(unitPos)
	charactersPos[unitPos[0]][unitPos[1]] = null
	set_cell(newPos, unit.sprite_id, Vector2i(0, 0))
	charactersPos[newPos[0]][newPos[1]] = unit
	boardFrontend.movementMode()
	# for movement in movements:
	# 	pass
