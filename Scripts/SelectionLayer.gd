extends TileMapLayer
const cell_consts = preload("res://Scripts/CellsConstants.gd")
@onready var cells_layer: TileMapLayer = $"../CellsLayer"		# Accessed to check if cell should be selectable
# @onready var cells_hl : TileMapLayer = $"../SelectionLayerHL"

var selected_cell = Vector2i(-10, -10)

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("press_board") and self.enabled:
		var click = local_to_map(get_global_mouse_position())
		if cells_layer.get_cell_tile_data(click) != null:
			erase_cell(selected_cell)
			selected_cell = click
			set_cell(selected_cell, cell_consts.MAIN_SRC_ID, cell_consts.SELECTED_CELL)
		else:
			pass
