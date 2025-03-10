extends Node

class_name TileMapLogic

@onready var cells_layer: TileMapLayer = $CellsLayer			# Holds the background of cells, namely Grey/Green/Red (Pre-gen/Correct/Incorrect)
@onready var subgrids_layer: TileMapLayer = $SubgridsLayer		# Visual for representing the Subgrid notations
@onready var numbers_layer: TileMapLayer = $NumbersLayer		# Visual representation for each number held on each board
@onready var notes_holder: Node2D = $NotesHolder				# Holds the layers for each note, each of which will represent its number
@onready var selection_layer: TileMapLayer = $SelectionLayer	# Record which cell is currently selected
@onready var characters_grid: Node2D = $CharactersGrid			# Holds characters on the grid

@export var knight : PackedScene
@export var wizard : PackedScene
@export var wordsmith : PackedScene

var players_count = 2
var boards = []				# formatted as [board object, start x, start y, Boolean on wether board is finished]
var player_starts = [Vector2i(2, 2), Vector2i(2, 4), Vector2i(4, 2), Vector2i(4, 4)]

const cell_consts = preload("res://Scripts/CellsConstants.gd")
const GAME_GRID_SIZE = 9
const MOVEMENT_GRID_SIZE = 10
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_grid(0, 0)
	var characters = []
	var starts = []
	var idx = 0
	for i in GameManager.GameState.Players:
		var newPlayer = knight.instantiate()
		newPlayer.name = str(GameManager.GameState.Players[i].id)
		characters.append(newPlayer)
		starts.append(player_starts[idx])
		idx += 1
	#var test_char = knight.instantiate()
	#test_char.init_char(1)
	#characters.append(test_char)
	#starts.append(player_starts[0])
	# characters_layer.init_layer(MOVEMENT_GRID_SIZE, characters, starts)

	characters_grid.init_grid(MOVEMENT_GRID_SIZE, characters, player_starts)
	
	# init_game()
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

func setCellCorrect(cell : Vector2i):
	cells_layer.set_cell(cell, cell_consts.MAIN_SRC_ID, cell_consts.CORRECT_CELL)

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
