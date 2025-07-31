extends Node

class_name CappedResource

var __on_change: Callable
var __on_max_change: Callable

var __max_amount
var max_amount: int:
	get:
		return __max_amount
	set(value):
		__max_amount = value
		__on_max_change.call(__max_amount)

var __amount: int = 0
var amount: int:
	get:
		return __amount
	set(value):
		if __can_die and __amount == 0:
			GlobalGameManager.end_game()
			return
		var new_amount = clamp(value, 0, __max_amount)
		if __amount != new_amount:
			__amount = new_amount
			__on_change.call(__amount)
			
					
var __can_die: bool

func _init(starting_amount: int, max_amount: int, on_change: Callable, on_max_change: Callable, can_die: bool):
	__on_change = on_change
	__on_max_change = on_max_change
	__max_amount = max_amount
	amount = starting_amount
	__can_die = can_die
	
func increment(delta: int):
	amount = amount + delta
	
func decrement(delta: int):
	amount = amount - delta

func have_enough(cost: int) -> bool:
	return amount >= cost 
	
# After init, need some way of sending the starting resource amount to the status bar
func send_signal():
	__on_change.call(__amount)
	__on_max_change.call(__max_amount)
	
