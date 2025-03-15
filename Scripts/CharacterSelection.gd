extends TileMapLayer
const cell_consts = preload("res://Scripts/CellsConstants.gd")
@onready var characterHighlight: TileMapLayer = $"../CharacterLayerHL"		# Accessed to check if cell should be selectable

var selected_cell = Vector2i(-10, -10)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("press_board") and self.enabled:
		var click = local_to_map(get_global_mouse_position() + Vector2(16, 16) )
		if characterHighlight.get_cell_tile_data(click) != null:
			erase_cell(selected_cell)
			selected_cell = click
			print(selected_cell)
			set_cell(selected_cell, cell_consts.CHAR_LYR_SRC_ID, cell_consts.CHAR_LYR_SELECTED)
		else:
			pass
