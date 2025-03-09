extends Node

class_name SudokuBoard

const NUMBERS = [1, 2, 3, 4, 5, 6, 7, 8, 9]
const NROWS = 9			# Y
const NCOLS = 9			# X
const SQUARE_SIZE = 3

var notes						# Holds the notes in each board
var puzzle_inputs				# Holds the current inputs from the player.
var puzzle						# The starting puzzle. Unchangeable after first generation. 
								# Causes matching spaces in the above 2 to be unfillable.
var solution					# The final unique solution. Unchangeable after first generation
var targetDifficulty = 1		# representing difficulty as int; 1 = easy , 5 = extreme

func _init(difficulty : int):
	targetDifficulty = difficulty; 
	solution = _initMatrix(NCOLS, NROWS)		# Initialise empty Solution matrix
	puzzle = _initMatrix(NCOLS, NROWS)			# Initialise empty puzzle matrix. These values cannot be changed by the player
	puzzle_inputs = _initMatrix(NCOLS, NROWS)	# Initialise empty matrix to store player inputs.
	notes = _initMatrix(NCOLS, NROWS)
	_initNotes(NCOLS, NROWS)
	# IMPORTANT! Currently representation of matrix is [Column][Row], which is [x][y]

# FUNCTIONAL SECTION
# Initialise the size of a grid and fill with -1s (flag for cell not yet initialised)
# In the puzzle we will also use flag 0 to mark initialised empty cell.
func _initMatrix(cols : int, rows : int):
	var outp = []
	outp.resize(cols)
	for i in range(cols):
		outp[i] = []
		outp[i].resize(rows)
		outp[i].fill(-1)
	return outp

func _initNotes(cols : int, rows : int):
	for i in range(cols):
		for j in range(rows):
			notes[i][j] = []

# Validates number in the specific location of the given grid at its current state
func validate(state, col : int, row : int, num : int):
	return (num not in state[col] and
			num not in getRow(state, row) and
			num not in getSubgrid(state, col, row))

# Generate solution recursively from a given state
func _makeSolution(state):
	for i in range(NCOLS):
		for j in range(NROWS):
			if state[i][j] == -1:
				var num = NUMBERS.duplicate()
				num.shuffle()
				for n in num:
					if validate(state, i, j, n):
						state[i][j] = n
						if _makeSolution(state):
							return true
						state[i][j] = -1
				return false
	return true

func makePuzzle():
	_makeSolution(solution)
	puzzle = solution.duplicate(true)
	var optimiser = 20					# Use this to make a few removes early on without having to check many cells
	var diff_removes = targetDifficulty * 7
	var removes = diff_removes + optimiser
	while removes > 0:					# In future would rather use a difficulty rater that can simulate solution tactics
		# Get random cell
		var row = randi_range(0, 8)
		var col = randi_range(0, 8)
		if puzzle[col][row] > 0:			# If cell is initialised and not empty
			var save = puzzle[col][row]		# Retain the original value of the cell
			puzzle[col][row] = 0			# Set it to empty (try to remove it)
			# Only goes into these ifs after the initial "optimiser" removals
			if removes < diff_removes:
				# Choose a cell that when removed retains only 1 solution
				if findUniqueSolutions(puzzle, 0) != 1:
					removes += 1		# Undo the last remove
					puzzle[col][row] = save
			elif removes == diff_removes:
				# Remove X numbers at random (optimally around 20?)
				if findUniqueSolutions(puzzle, 0) != 1:
					removes += optimiser + 1			# Undo all removes
					puzzle = solution.duplicate(true)	# Reset the puzzle to the starting position
			removes -= 1
	# Evaluate difficulty without it
	# If desired difficulty not reached and no more "removable" cells, restart.
	# Denote removable cells somehow?
	puzzle_inputs = puzzle.duplicate(true)

func makePuzzleFromPartial(partial_solution: Array, partial_puzzle: Array):
	_makeSolution(partial_solution)
	solution = partial_solution
	# Try to solve using partial puzzle
	# If unsolvable (or not just 1 solution), add a number in the uninitiated puzzle
	# Evaluate difficulty, if too easy, try again, else add another until only 1 solution
	pass

func findUniqueSolutions(state, solutions_count):
	for col in range(NCOLS):
		for row in range(NROWS):
			if state[col][row] == 0:
				for num in range(1, 10):
					if validate(state, col, row, num):
						state[col][row] = num
						solutions_count = findUniqueSolutions(state, solutions_count)
						state[col][row] = 0
				return solutions_count
	solutions_count += 1
	return solutions_count

# Shifts the solution or puzzle board by a specified amount for use when generating overlapping boards
func stateShift(state, col_offset : int, row_offset : int) -> Array:
	var copy = _initMatrix(NCOLS, NROWS)
	for col in range(9):
		var new_col = col + col_offset
		if new_col >= 0 and new_col < NCOLS:
			for row in range(9):
				var new_row = row + row_offset
				if new_row >= 0 and new_row < NROWS:
					copy[new_col][new_row] = state[col][row]
	return copy

# Return array of all possible values for a specified cell
func getCellPossibilities(state, col : int, row : int) -> Array:
	var outp = []
	for i in range(1, 10):
		if validate(state, col, row, i):
			outp.append(i)
	return outp

# In getters use "state" as input to make them usable for both solution and puzzle grid checking.
func getRow(state, row : int):
	var row_nums = []
	for i in range(NROWS):
		row_nums.append(state[i][row])
	return row_nums

func getSubgrid(state, col : int, row : int):
	var subgrid = []
	var r = (row / SQUARE_SIZE) * SQUARE_SIZE
	var c = (col / SQUARE_SIZE) * SQUARE_SIZE
	for i in range(c, c + SQUARE_SIZE):
		for j in range(r, r + SQUARE_SIZE):
			subgrid.append(state[i][j])
	return subgrid

# INTERACTION SECTION
func getCellSolution(col : int, row : int) -> Array:
	return solution[col][row]
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
