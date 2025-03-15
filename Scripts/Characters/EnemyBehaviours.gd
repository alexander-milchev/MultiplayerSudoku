extends Node

class_name EnemyBehaviours

var charactersGrid : Node2D
var tileMapsLayer : Node2D
var cellDirtLayer : TileMapLayer

func _init(charGrid, tileMaps, cdl) -> void:
	charactersGrid = charGrid
	tileMapsLayer = tileMaps
	cellDirtLayer = cdl

func performEnemyTurnWithBehaviour(bhvr : int, self_idx : int):
	match bhvr:
		0:
			_blob_behaviour(self_idx)
	
	charactersGrid.advanceTurnOrder.rpc()

func _move_towards(start : Vector2i, target : Vector2i, remaining_spd : int):
	var x_dist = abs(start.x - target.x)
	var y_dist = abs(start.y - target.y)
	var movements = []
	if x_dist + y_dist == 0:
		return movements				# Target reached
	var adjacents = charactersGrid.getValidNeighbours(start.x, start.y)
	var closest = 99
	var closest_move = null
	for cell in adjacents:
		var new_dist = charactersGrid.getDistance(target, Vector2i(cell[1], cell[2]))
		if closest > new_dist:
			closest = new_dist
			closest_move = cell
	if closest_move != null:
		movements.append(Vector2i(closest_move[1], closest_move[2]))
		remaining_spd -= 1
	else:
		return movements				# No Valid Moves
	
	if remaining_spd == 0:
		return movements			
	else:
		movements.append_array(_move_towards(movements[-1], target, remaining_spd))
	return movements

func _move_adjacent_to(start : Vector2i, target : Vector2i, spd : int):
	var adjacents = charactersGrid.getValidNeighbours(target.x, target.y)
	var closest = 99
	var final_target
	for cell in adjacents:
		var new_dist = charactersGrid.getDistance(start, Vector2i(cell[1], cell[2]))
		if closest > new_dist:
			closest = new_dist
			final_target = cell
	return _move_towards(start, Vector2i(final_target[1], final_target[2]), spd)

func _blob_behaviour(self_idx : int):
	var self_pos = charactersGrid.getPosition(charactersGrid.characters[self_idx])
	var closest_playable : CharacterBase
	var shortest_distance = 99
	for char in charactersGrid.characters:
		if char.playerID != null:
			var new_dist = charactersGrid.getDistance(self_pos, charactersGrid.getPosition(char))
			if new_dist < shortest_distance:
				shortest_distance = new_dist
				closest_playable = char
	print(self_pos)
	var target = charactersGrid.getPosition(closest_playable)
	var movements = _move_adjacent_to(self_pos, target, charactersGrid.characters[self_idx].speed)
	print("Moving enemy by ", movements)
	if movements != []:
		charactersGrid.moveCharacter.rpc(self_idx, movements)
	
	self_pos = charactersGrid.getPosition(charactersGrid.characters[self_idx])
	if charactersGrid.getDistance(self_pos, target) <= charactersGrid.characters[self_idx].reach:
		var dirtied = tileMapsLayer.getCellsAdjacentToChar(self_pos)
		for cell in dirtied:
			cellDirtLayer.goopCell.rpc(cell)
		charactersGrid.damageUnit.rpc(target, 1)
		charactersGrid.damageUnit.rpc(self_pos, 2)		# Then die
	
	
