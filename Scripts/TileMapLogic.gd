extends Node

class_name TileMapLogic

@onready var cells_layer: TileMapLayer = $CellsLayer			# Holds the background of cells, namely Grey/Green/Red (Pre-gen/Correct/Incorrect)
@onready var subgrids_layer: TileMapLayer = $SubgridsLayer		# Visual for representing the Subgrid notations
@onready var numbers_layer: TileMapLayer = $NumbersLayer		# Visual representation for each number held on each board
@onready var notes_holder: Node2D = $NotesHolder				# Holds the layers for each note, each of which will represent its number
@onready var selection_layer_hl : TileMapLayer = $SelectionLayerHL	# Holds highlight of vision of a character
@onready var selection_layer: TileMapLayer = $SelectionLayer	# Record which cell is currently selected
@onready var characters_grid: Node2D = $CharactersGrid			# Holds characters on the grid

@export var knight : PackedScene
@export var wizard : PackedScene
@export var wordsmith : PackedScene

@export var blob : PackedScene
@export var monke : PackedScene
@export var mushroom : PackedScene

var players_count = 2
var boards = []				# formatted as [board object, start x, start y, Boolean on wether board is finished]
var player_starts = [Vector2i(2, 2), Vector2i(2, 4), Vector2i(4, 2), Vector2i(4, 4)]
var enemy_starts = [Vector2i(8, 8), Vector2i(6, 8), Vector2i(8, 6), Vector2i(6, 6)]

const cell_consts = preload("res://Scripts/CellsConstants.gd")
const GAME_GRID_SIZE = 9
const MOVEMENT_GRID_SIZE = 10

func _ready() -> void:
	create_grid(0, 0)
	var characters = []
	var starts = []
	var idx = 0
	for i in GameManager.GameState.Players:
		var newPlayer
		match GameManager.GameState.Players[i].character:
			0:
				newPlayer = knight.instantiate()
			1:
				newPlayer = wizard.instantiate()
			2:
				newPlayer = wordsmith.instantiate()
			_:
				newPlayer = knight.instantiate()
		newPlayer.name = GameManager.GameState.Players[i].name + str(GameManager.GameState.Players[i].id)
		newPlayer.init_char(GameManager.GameState.Players[i].id)
		characters.append(newPlayer)
		starts.append(player_starts[idx])
		if multiplayer.get_unique_id() == newPlayer.playerID:
			characters_grid.ownedCharacterIndex = idx
		idx += 1
	
	# Set number of players
	
	for i in range(0, 3):
		var newEnemy
		match i:
	#		0:
	#			pass
	#			newEnemy = mushroom.instantiate()
	#			newEnemy.init_enemy()
	#		1:
	#			pass
	#			newEnemy = monke.instantiate()
	#			newEnemy.init_enemy()
			2:
				newEnemy = blob.instantiate()
				newEnemy.init_enemy()
			_:
				newEnemy = blob.instantiate()
				newEnemy.init_enemy()
		newEnemy.name = "Enemy" + str(idx)
		characters.append(newEnemy)
		starts.append(enemy_starts[i])
		idx += 1
	characters_grid.init_grid(MOVEMENT_GRID_SIZE, characters, starts)
	
	display_boards_numbers()
	

# Sets all the required empty cells and initialises the subgrid divisions
func create_grid(start_x : int, start_y : int):
	for i in range(GAME_GRID_SIZE):
		for j in range(GAME_GRID_SIZE):
			cells_layer.set_cell(Vector2i(i + start_x, j + start_y), cell_consts.MAIN_SRC_ID, cell_consts.BLANK_CELL)
			var subsec = cell_consts.TOP_LEFT + Vector2i((i + start_x) % 3, (j + start_y) % 3)
			subgrids_layer.set_cell(Vector2i(i + start_x, j + start_y), cell_consts.MAIN_SRC_ID ,subsec)

func init_game(diff: int):
	# Create one new board for now
	var game = SudokuBoard.new(diff)
	game.makePuzzle()
	boards.append([game, 0, 0, false])
	GameManager.GameState.Boards[1] = {
		"Inputs" : game.puzzle_inputs,
		"Puzzle" : game.puzzle,
		"Solution" : game.solution,
		"X_Start" : 0,
		"Y_Start" : 0
	}
	display_boards_numbers()

func display_boards_numbers():
	for elem in boards:
		var board : SudokuBoard
		board = elem[0]
		var start_x = elem[1]
		var start_y = elem[2]
		for col in range(board.NCOLS):
			for row in range(board.NROWS):
				var coords = getNumberCoords(board.puzzle[col][row])
				if coords != cell_consts.NUMBER_0:
					numbers_layer.set_cell(Vector2i(col + start_x, row + start_y), cell_consts.MAIN_SRC_ID, coords)

# Visualisations
func setCellUnconfirmed(cell : Vector2i):
	cells_layer.set_cell(cell, cell_consts.MAIN_SRC_ID, cell_consts.UNCHECKED_CELL)

@rpc("any_peer", "call_local")
func setCellCorrect(cell : Vector2i):
	cells_layer.set_cell(cell, cell_consts.MAIN_SRC_ID, cell_consts.CORRECT_CELL)

@rpc("any_peer", "call_local")
func setCellIncorrect(cell : Vector2i):
	cells_layer.set_cell(cell, cell_consts.MAIN_SRC_ID, cell_consts.INCORRECT_CELL)

func setNumberAt(num : int, cell : Vector2i):
	numbers_layer.set_cell(cell, cell_consts.MAIN_SRC_ID, getNumberCoords(num))

func isNumEqualToAnswer(num : int, cell : Vector2i):
	return num == boards[0][0].solution[cell[0]][cell[1]]

func setNoteAt(note : int, cell : Vector2i):
	notes_holder.get_child(note - 1).set_cell(cell, cell_consts.MAIN_SRC_ID, getNoteCoords(note))

func deleteNoteAt(note : int, cell : Vector2i):
	notes_holder.get_child(note - 1).erase_cell(cell)

# Helper functions
# 1	  2	  3	  4	 col/row
#	  2	  2			1
# 2	  1	  1	  2		2
#		c				Character coords = (3, 3)
# 2	  1	  1	  2		3
#	  2	  2			4
func getDistanceFromChar(char_pos : Vector2i, cell_pos : Vector2i):
	var converted_pos = Vector2(char_pos) - Vector2(0.5, 0.5)
	var x_dist = abs(converted_pos.x - cell_pos.x)
	var y_dist = abs(converted_pos.y - cell_pos.y)
	return x_dist + y_dist

func getCellsAdjacentToChar(char_pos: Vector2i):
	return [char_pos - Vector2i(1, 1), char_pos - Vector2i(0, 1), char_pos - Vector2i(1, 0), char_pos]

func displayVision():
	var char_pos = characters_grid.getPosition(characters_grid.characters[characters_grid.ownedCharacterIndex])
	var vision = characters_grid.characters[characters_grid.ownedCharacterIndex].vision
	selection_layer_hl.clear()							# Clear layer before drawing
	for col in range(characters_grid.charactersPos.size() - 1):
		for row in range(characters_grid.charactersPos[col].size() - 1):
			if getDistanceFromChar(char_pos, Vector2i(col, row)) <= vision:
				selection_layer_hl.set_cell(Vector2i(col, row), 1, Vector2i(0, 0))

func getAllInVision():
	var char_pos = characters_grid.getPosition(characters_grid.characters[characters_grid.ownedCharacterIndex])
	var vision = characters_grid.characters[characters_grid.ownedCharacterIndex].vision
	var cells_in_vision = []
	for col in range(characters_grid.charactersPos.size() - 1):
		for row in range(characters_grid.charactersPos[col].size() - 1):
			if getDistanceFromChar(char_pos, Vector2i(col, row)) <= vision:
				cells_in_vision.append(Vector2i(col, row))
	return cells_in_vision

func getNumberCoords(num : int) -> Vector2i:
	match num:
		1:
			return cell_consts.NUMBER_1
		2:
			return cell_consts.NUMBER_2
		3:
			return cell_consts.NUMBER_3
		4:
			return cell_consts.NUMBER_4
		5:
			return cell_consts.NUMBER_5
		6:
			return cell_consts.NUMBER_6
		7:
			return cell_consts.NUMBER_7
		8:
			return cell_consts.NUMBER_8
		9:
			return cell_consts.NUMBER_9
		_:
			return cell_consts.NUMBER_0

func getNoteCoords(note : int) -> Vector2i:
	match note:
		1:
			return cell_consts.NOTE_1
		2:
			return cell_consts.NOTE_2
		3:
			return cell_consts.NOTE_3
		4:
			return cell_consts.NOTE_4
		5:
			return cell_consts.NOTE_5
		6:
			return cell_consts.NOTE_6
		7:
			return cell_consts.NOTE_7
		8:
			return cell_consts.NOTE_8
		9:
			return cell_consts.NOTE_9
		_:
			return cell_consts.NUMBER_0
