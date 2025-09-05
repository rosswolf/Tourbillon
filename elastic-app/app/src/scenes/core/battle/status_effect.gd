extends Node

class_name StatusEffect

enum Type {
	UNKNOWN,
	TRIPPED, # move = 0
	SLOW, # move = move - 1 (for n turns)
	CARELESS, # set block to 0 (immediate only)
	VULNERABLE, # take more damage for n turns
	WEAK, # attack for less damage for n turns
	MARKED, # take 1 more damage each time attacked (n turns)
	POISONED, # end of turn take damage per poison.  (n turns)
	STUNNED, # do nothing  (n turns)
	FLYING, # take half damage from attacks unless ranged or counters
}

#
#class EffectMap:
	#var
