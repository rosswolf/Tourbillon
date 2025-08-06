extends Node

class_name GoalManager

func _init():
	#GlobalSignals.core_goal_succeeded.connect()
	#GlobalSignals.core_goal_failed.connect()
	GlobalSignals.core_begin_turn.connect(__on_begin_turn)
	
func __on_begin_turn():
	var goal: Goal = Goal.load_goal("survival_1")
	GlobalSignals.signal_core_goal_created(goal.instance_id)
