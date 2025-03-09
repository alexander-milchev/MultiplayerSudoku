extends Node2D

class_name CharacterBase

var health						# If HP = 0, incapacitated?
var reach						# Reach of abilities
var speed						# Max movement per turn
var vision						# Range of placing numbers/notes. Leave at 0 for enemies
var playerID					# For player characters only. Leave null for enemies

var behaviour					# For enemies only, leave null if playable

var sprite_id					# The Atlas ID of the sprite for the corresponding unit in the tileset

#func _init(hp : int, rch : int, spd : int, vis : int, id : int, PID : int):
#	health = hp
#	speed = spd
#	reach = rch
#	vision = vis
#	sprite_id = id
#	playerID = PID

func attack():
	pass

func hint():
	pass

func clean():
	pass

func skill():
	pass
