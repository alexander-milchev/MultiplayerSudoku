extends TileMapLayer

const CELL_IDS = preload("res://Scripts/CellsConstants.gd")

@rpc("any_peer", "call_local")
func goopCell(cell):
	self.set_cell(cell, CELL_IDS.DIRT_LYR_SRC_ID, CELL_IDS.GOOP)

@rpc("any_peer", "call_local")
func clearCell(cell):
	self.set_cell(cell, -1)
