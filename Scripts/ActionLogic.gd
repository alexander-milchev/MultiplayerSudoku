extends GridContainer

@onready var frontend = $"../.."

@onready var tileMapLayer = $"../../TileMaps"
@onready var characterGrid = $"../../TileMaps/CharactersGrid"
@onready var cellDirtLayer = $"../../TileMaps/CellDirtLayer"
@onready var characterLayerHighlight = $"../../TileMaps/CharacterLayerHL"
@onready var characterLayerSelect = $"../../TileMaps/CharacterLayerSelect"
@onready var cellLayerHighlight = $"../../TileMaps/SelectionLayerHL"
@onready var cellLayerSelect = $"../../TileMaps/SelectionLayer"
@onready var moveSelectGrid = $"../MovementSelectionGrid"

@onready var confirmContainer: PanelContainer = $ConfirmContainer
@onready var hintContainer: PanelContainer = $HintContainer
@onready var mopContainer: PanelContainer = $MopContainer
@onready var attackContainer: PanelContainer = $AttackContainer
@onready var abilityContainer: PanelContainer = $AbilityContainer
@onready var backContainer : PanelContainer = $BackContainer
@onready var moveContainer : PanelContainer = $MoveContainer
@onready var endTurnContainer: PanelContainer = $EndTurnContainer

var currentAction = -1			# -1 = none, 0 = attack, 1 = hint, 2 = mop, 3 = ability, 4 = move
var actionAvailable = false		# Has action been used this turn
var movementAvailable = 0		# Remaining movement this turn
var movementAvailableMoveStart = 0	# Save movement at the start of a movement action

func _ready() -> void:
	confirmContainer.get_child(0).pressed.connect(confirm.bind())
	hintContainer.get_child(0).pressed.connect(hint.bind())
	mopContainer.get_child(0).pressed.connect(clean.bind())
	attackContainer.get_child(0).pressed.connect(attack.bind())
	abilityContainer.get_child(0).pressed.connect(skill.bind())
	backContainer.get_child(0).pressed.connect(back.bind())
	moveContainer.get_child(0).pressed.connect(move.bind())
	endTurnContainer.get_child(0).pressed.connect(endTurn.bind())
	
	characterGrid.advanceTurnOrder()

func prepareTurn():
	actionAvailable = true
	confirmContainer.get_child(0).disabled = true
	backContainer.get_child(0).disabled = true
	endTurnContainer.get_child(0).disabled = false
	
	hintContainer.get_child(0).disabled = false
	mopContainer.get_child(0).disabled = false
	attackContainer.get_child(0).disabled = false
	abilityContainer.get_child(0).disabled = false
	
	# frontend.disableMovementButton(false)
	moveContainer.get_child(0).disabled = false
	movementAvailable = characterGrid.characters[characterGrid.ownedCharacterIndex].speed
	movementAvailableMoveStart = movementAvailable
	
	tileMapLayer.displayVision()				# Display vision for placing numbers

func toggleActions():
	confirmContainer.get_child(0).disabled = !confirmContainer.get_child(0).disabled
	backContainer.get_child(0).disabled = !backContainer.get_child(0).disabled
	endTurnContainer.get_child(0).disabled = !endTurnContainer.get_child(0).disabled
	
	if actionAvailable:
		hintContainer.get_child(0).disabled = !hintContainer.get_child(0).disabled
		mopContainer.get_child(0).disabled = !mopContainer.get_child(0).disabled
		attackContainer.get_child(0).disabled = !attackContainer.get_child(0).disabled
		abilityContainer.get_child(0).disabled = !abilityContainer.get_child(0).disabled
	else:
		hintContainer.get_child(0).disabled = true
		mopContainer.get_child(0).disabled = true
		attackContainer.get_child(0).disabled = true
		abilityContainer.get_child(0).disabled = true
	
	moveContainer.get_child(0).disabled = !moveContainer.get_child(0).disabled
	frontend.toggleSelectButtons()

func switchToCharLayer():
	cellLayerSelect.enabled = false
	characterLayerSelect.enabled = true

func switchToPuzzleLayer():
	cellLayerSelect.enabled = true
	characterLayerHighlight.clear()
	characterLayerSelect.clear()
	characterLayerSelect.selected_cell =  Vector2i(-10, -10)
	characterLayerSelect.enabled = false

func attack():
	toggleActions()
	currentAction = 0
	switchToCharLayer()						# Enable selecting a character
	characterGrid.displayReachFromOwner()	# Display the reach of the attack

func hint():
	toggleActions()
	currentAction = 1
	tileMapLayer.displayVision()

func clean():
	toggleActions()
	currentAction = 2
	tileMapLayer.displayVision()

func skill():
	toggleActions()
	currentAction = 3
	pass

func confirm():
	match currentAction:
		0:										# Attack
			var selection = characterLayerSelect.selected_cell
			if characterGrid.charactersPos[selection.x][selection.y] == null:
				print("Please select a non-empty space")
			else:
				var target = characterGrid.charactersPos[selection.x][selection.y]
				if target.playerID == null:
					characterGrid.damageUnit.rpc(selection, 1)
					actionAvailable = false
				else:
					print("Please select an enemy")
		1:										# Hint
			var selected = tileMapLayer.getAllInVision()
			for cell in selected:
				if frontend._find_puzzle_on_boards(cell.x, cell.y) == 0:		# Only check the inputted ones
					var inp = frontend.find_input_on_boards(cell.x, cell.y)
					if tileMapLayer.isNumEqualToAnswer(inp, cell):
						tileMapLayer.setCellCorrect.rpc(cell)
						actionAvailable = false
					else:
						tileMapLayer.setCellIncorrect.rpc(cell)
						actionAvailable = false
		2:										# Mop
			var selected = cellLayerSelect.selected_cell
			var vis = characterGrid.characters[characterGrid.ownedCharacterIndex].vision
			var dist = tileMapLayer.getDistanceFromChar(characterGrid.getPosition(characterGrid.characters[characterGrid.ownedCharacterIndex]), selected)
			if dist > vis:				# Only within vision
				print("Can't clean there. Out of vision")
			else:
				if cellDirtLayer.get_cell_tile_data(selected) == null:
					print("Already clean")
				else:
					cellDirtLayer.clearCell.rpc(selected)
					actionAvailable = false
		3:										# Ability
			pass
	back()

func back():
	match currentAction:
		0:
			switchToPuzzleLayer()
		1:
			tileMapLayer.displayVision()				# Display vision for placing numbers
		2:
			tileMapLayer.displayVision()
		3:
			pass
		4:
			cellLayerSelect.enabled = !cellLayerSelect.enabled
			moveSelectGrid.visible = !moveSelectGrid.visible
			confirmContainer.get_child(0).disabled = !confirmContainer.get_child(0).disabled
			movementAvailable = movementAvailableMoveStart
	currentAction = -1
	toggleActions()

func toggleMove():
	currentAction = -1
	cellLayerSelect.enabled = !cellLayerSelect.enabled
	moveSelectGrid.visible = !moveSelectGrid.visible
	# action_buttons.visible = !action_buttons.visible
	toggleActions()
	confirmContainer.get_child(0).disabled = !confirmContainer.get_child(0).disabled

func move():
	# Disable selection layer; Enable movement selection buttons
	toggleMove()
	currentAction = 4
	moveSelectGrid.movementInputs = []
	moveSelectGrid.updatePossibleDirections(characterGrid.getPosition(characterGrid.characters[characterGrid.ownedCharacterIndex]))
	# If movement buttons are set to off, clear the current saved inputs

func endTurn():
	print("Ending turn")
	actionAvailable = false
	confirmContainer.get_child(0).disabled = true
	backContainer.get_child(0).disabled = true
	endTurnContainer.get_child(0).disabled = true
	
	hintContainer.get_child(0).disabled = true
	mopContainer.get_child(0).disabled = true
	attackContainer.get_child(0).disabled = true
	abilityContainer.get_child(0).disabled = true
	
	moveContainer.get_child(0).disabled = true
	#frontend.disableMovementButton(true)
	
	cellLayerHighlight.clear()
	characterGrid.advanceTurnOrder.rpc()
