extends Node2D

class_name CharacterBase

var health						# If HP = 0, incapacitated?
var reach						# Reach of abilities
var speed						# Max movement per turn
var vision						# Range of placing numbers/notes. Leave at 0 for enemies
var playerID					# For player characters only. Leave null for enemies

var bhvr						# For enemies only. Null for playables. Denotes which bhvr function to use for this enemy

func attack():
	pass

func hint():
	pass

func clean():
	pass

func skill():
	pass
