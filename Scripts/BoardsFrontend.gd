extends Node

@export var tile_maps: Node2D
@export var selection_grid: GridContainer			# Contains the buttons 1-9 for inputting values at the selected grid space
@export var selection_layer: TileMapLayer
@export var movement_buttons: GridContainer
@export var action_buttons: GridContainer
@export var characters_grid: Node2D

var notes_flag = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_selection()

func host_create_game(diff: int):
	tile_maps.init_game(diff)

func client_receive_game():
	tile_maps.boards = []
	var game = SudokuBoard.new(1)
	var board_states = GameManager.GameState.Boards
	for i in board_states:
		game.solution = board_states[i].Solution
		game.puzzle = board_states[i].Puzzle
		game.puzzle_inputs = board_states[i].Inputs
		tile_maps.boards.append([game, board_states[i].X_Start, board_states[i].Y_Start, false])
	tile_maps.display_boards_numbers()

func create_selection():
	for i in range(1, 10):
		create_selection_button(i)
	var notes_button = Button.new()
	notes_button.name = "NoteButton"
	notes_button.toggle_mode = true
	# notes_button.text = "Notes"
	# notes_button.add_theme_font_size_override("default", 30)
	notes_button.icon = ResourceLoader.load("res://Assets/Buttons/ButtonsNotes.png")
	notes_button.expand_icon = true
	notes_button.custom_minimum_size = Vector2(48, 48)
	notes_button.button_down.connect(notesFlip)
	selection_grid.add_child(notes_button)
	
	#var movement_button = Button.new()
	#movement_button.name = "MovementButton"
	#movement_button.icon = ResourceLoader.load("res://Assets/Buttons/ButtonsMovement.png")
	#movement_button.expand_icon = true
	#movement_button.custom_minimum_size = Vector2(48, 48)
	#movement_button.button_down.connect(movementMode)
	#movement_button.disabled = true
	#selection_grid.add_child(movement_button)

#func movementMode():
	# Disable selection layer; Enable movement selection buttons
	#selection_layer.enabled = !selection_layer.enabled
	#movement_buttons.visible = !movement_buttons.visible
	#action_buttons.visible = !action_buttons.visible
	#movement_buttons.movementInputs = []
	#movement_buttons.updatePossibleDirections(characters_grid.getPosition(characters_grid.characters[characters_grid.ownedCharacterIndex]))
	# If movement buttons are set to off, clear the current saved inputs

func toggleSelectButtons():
	for button in selection_grid.get_children():
		button.disabled = !button.disabled

func disableSelectButtons(dis : bool):
	for button in selection_grid.get_children():
		button.disabled = dis

# func disableMovementButton(dis : bool):
#	if selection_grid.get_child(10) != null:
#		selection_grid.get_child(10).disabled = dis
#	pass

func notesFlip():
	notes_flag = !notes_flag
	print(notes_flag)

func create_selection_button(num : int):
	var button = Button.new()
	button.text = str(num)
	button.name = "Button" + str(num)
	button.add_theme_font_size_override("default", 42)
	button.custom_minimum_size = Vector2(48, 48)
	button.pressed.connect(_on_select_grid_button_pressed.bind(int(button.text)))
	selection_grid.add_child(button)

func _on_select_grid_button_pressed(num_pressed :  int):
	var selected_coords = selection_layer.selected_cell
	if selected_coords != Vector2i(-10, -10) and selection_layer.enabled:
		if notes_flag:
			_notes_input.rpc(num_pressed, selected_coords)
		else:								# placing a number
			if characters_grid.currentTurnCharacter != characters_grid.ownedCharacterIndex:
				print("Wait for your turn to place numbers")
			else:							# Only on your turn
				var vis = characters_grid.characters[characters_grid.ownedCharacterIndex].vision
				var dist = tile_maps.getDistanceFromChar(characters_grid.getPosition(characters_grid.characters[characters_grid.ownedCharacterIndex]), selected_coords)
				if dist > vis:				# Only within vision
					print("Can't place there. Out of vision")
				else:
					_number_input.rpc(num_pressed, selected_coords)

@rpc("any_peer", "call_local")
func _notes_input(num_pressed : int, selected_coords : Vector2i):
	for elem in tile_maps.boards:
		if _is_cell_within_board(elem[0], elem[1], elem[2], selected_coords[0], selected_coords[1]):
			var col = selected_coords[0] - elem[1]			# Getting local row/col for the board
			var row = selected_coords[1] - elem[2]
			if elem[0].puzzle[col][row] == 0:				# If the selected space is fillable (not part of the puzzle)
				if elem[0].puzzle_inputs[col][row] == 0:	# Can only place notes if the cell is empty
					if num_pressed in elem[0].notes[col][row]:
						elem[0].notes[col][row].erase(num_pressed)
						tile_maps.deleteNoteAt(num_pressed, selected_coords)
					else:		# Only add note if it's not already in the list. Otherwise remove it
						elem[0].notes[col][row].append(num_pressed)
						tile_maps.setNoteAt(num_pressed, selected_coords)

@rpc("any_peer", "call_local")
func _number_input(num_pressed : int, selected_coords : Vector2i):
	for elem in tile_maps.boards:
		if _is_cell_within_board(elem[0], elem[1], elem[2], selected_coords[0], selected_coords[1]):
			var col = selected_coords[0] - elem[1]			# Getting local row/col for the board
			var row = selected_coords[1] - elem[2]
			if elem[0].puzzle[col][row] == 0:				# If the selected space is fillable (not part of the puzzle)
				elem[0].puzzle_inputs[col][row] = num_pressed
				if elem[0].puzzle_inputs == elem[0].solution :
					print("Complete!")
					elem[3] = true
				else:
					elem[3] = false
				# First clear all notes, then assign new number
				for i in range(1, 10):
					tile_maps.deleteNoteAt(i, selected_coords)
				tile_maps.setNumberAt(num_pressed, selected_coords)
				
				tile_maps.setCellUnconfirmed(selected_coords)			# Clear any hints
				
				# Mark cell as correct/wrong
				# if tile_maps.isNumEqualToAnswer(num_pressed, selected_coords):
				# 	tile_maps.setCellCorrect(selected_coords)
				# else:
				#	tile_maps.setCellIncorrect(selected_coords)

#@rpc("any_peer", "call_local")
#func _selection_input(num_pressed :  int, selected_coords : Vector2i, is_note : bool):
#	var is_placable = false
#	for elem in tile_maps.boards:
#		if _is_cell_within_board(elem[0], elem[1], elem[2], selected_coords[0], selected_coords[1]):
#			var col = selected_coords[0] - elem[1]			# Getting local row/col for the board
#			var row = selected_coords[1] - elem[2]
#			if elem[0].puzzle[col][row] == 0:				# If the selected space is fillable (not part of the puzzle)
#				is_placable = true
#				# Check if we need to fill the notes or numbers
#				if is_note:				# Insertion of Note in notes; Only allowed if no number already present
#					if elem[0].puzzle_inputs[col][row] == 0:
#						if num_pressed in elem[0].notes[col][row]:
#							elem[0].notes[col][row].erase(num_pressed)
#							tile_maps.deleteNoteAt(num_pressed, selected_coords)
#						else:		# Only add note if it's not already in the list. Otherwise remove it
#							elem[0].notes[col][row].append(num_pressed)
#							tile_maps.setNoteAt(num_pressed, selected_coords)
#				else:						# Insertion of Number in puzzle
#					elem[0].puzzle_inputs[col][row] = num_pressed
#					if elem[0].puzzle_inputs == elem[0].solution :
#						print("Complete!")
#						elem[3] = true
#					else:
#						elem[3] = false
#					# First clear all notes, then assign new number
#					for i in range(1, 10):
#						tile_maps.deleteNoteAt(i, selected_coords)
#					tile_maps.setNumberAt(num_pressed, selected_coords)
#					
#					tile_maps.setCellUnconfirmed(selected_coords)			# Clear any hints
#					
#					# Mark cell as correct/wrong
#					# if tile_maps.isNumEqualToAnswer(num_pressed, selected_coords):
#					# 	tile_maps.setCellCorrect(selected_coords)
#					# else:
#					#	tile_maps.setCellIncorrect(selected_coords)

func _find_answer_on_boards(col : int, row : int):		# Input is from row/col of buttons matrix
	for elem in tile_maps.boards:						# Convert to board row/col
										# If the row and column are within the bounds of the given board
		if _is_cell_within_board(elem[0], elem[1], elem[2], col, row):
			return elem[0].solution[col - elem[1]][row - elem[2]]

func _find_puzzle_on_boards(col : int, row : int):		# Input is from row/col of buttons matrix
	for elem in tile_maps.boards:						# Convert to board row/col
										# If the row and column are within the bounds of the given board
		if _is_cell_within_board(elem[0], elem[1], elem[2], col, row):
			return elem[0].puzzle[col - elem[1]][row - elem[2]]

func find_input_on_boards(col : int, row : int):		# Input is from row/col of buttons matrix
	for elem in tile_maps.boards:						# Convert to board row/col
										# If the row and column are within the bounds of the given board
		if _is_cell_within_board(elem[0], elem[1], elem[2], col, row):
			return elem[0].puzzle_inputs[col - elem[1]][row - elem[2]]

func _is_cell_within_board(board : SudokuBoard, start_col : int, start_row : int, col : int, row : int):
	return (row >= start_row and row < start_row + board.NROWS and col >= start_col and col < start_col + board.NCOLS)

func prepareTurn():
	action_buttons.prepareTurn()
