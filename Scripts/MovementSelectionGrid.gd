extends GridContainer

@onready var upButtonContainer: PanelContainer = $UpContainer
@onready var rightButtonContainer: PanelContainer = $RightContainer
@onready var confirmButtonContainer: PanelContainer = $ConfirmContainer
@onready var leftButtonContainer: PanelContainer = $LeftContainer
@onready var downButtonContainer: PanelContainer = $DownContainer
# @onready var charactersLayer: TileMapLayer = $"../../TileMaps/CharactersLayer"
@onready var charactersGrid: Node2D = $"../../TileMaps/CharactersGrid"

var movementInputs = []				# Stores the movement inputs of the active character
var currentLocation					# Save the intermediary location in between movements

func _ready() -> void:
	leftButtonContainer.get_child(0).pressed.connect(left.bind())
	upButtonContainer.get_child(0).pressed.connect(up.bind())
	rightButtonContainer.get_child(0).pressed.connect(right.bind())
	downButtonContainer.get_child(0).pressed.connect(down.bind())
	confirmButtonContainer.get_child(0).pressed.connect(confirm.bind())

func updatePossibleDirections(position : Vector2i):
	disableButtons()
	currentLocation = position
	var valid = charactersGrid.getValidNeighbours(position[0], position[1])
	if movementInputs == []:
		confirmButtonContainer.get_child(0).disabled = true
	for i in valid:
		if i[0] == "Left":
			leftButtonContainer.get_child(0).disabled = false
		if i[0] == "Up":
			upButtonContainer.get_child(0).disabled = false
		if i[0] == "Down":
			downButtonContainer.get_child(0).disabled = false
		if i[0] == "Right":
			rightButtonContainer.get_child(0).disabled = false

func disableButtons():
	rightButtonContainer.get_child(0).disabled = true
	leftButtonContainer.get_child(0).disabled = true
	upButtonContainer.get_child(0).disabled = true
	downButtonContainer.get_child(0).disabled = true
	confirmButtonContainer.get_child(0).disabled = false

func left():
	var new_pos = currentLocation - Vector2i(1, 0)
	movementInputs.append(new_pos)
	updatePossibleDirections(new_pos)

func right():
	var new_pos = currentLocation + Vector2i(1, 0)
	movementInputs.append(new_pos)
	updatePossibleDirections(new_pos)

func up():
	var new_pos = currentLocation - Vector2i(0, 1)
	movementInputs.append(new_pos)
	updatePossibleDirections(new_pos)

func down():
	var new_pos = currentLocation + Vector2i(0, 1)
	movementInputs.append(new_pos)
	updatePossibleDirections(new_pos)

func confirm():
	print(movementInputs)
	charactersGrid.moveCharacter(charactersGrid.characters[charactersGrid.currentActiveCharacter], movementInputs)
	
