extends Node

class_name GoalManager

var active_goal: Goal
const available_goals = ["survival_1","play_cards_1","activate_buildings_1"]

func _init():
	GlobalSignals.core_goal_succeeded.connect(__on_goal_complete)
	GlobalSignals.core_goal_failed.connect(__on_goal_complete)
	GlobalSignals.core_begin_turn.connect(__on_begin_turn)
	
func __on_begin_turn():
	active_goal = Goal.load_goal(available_goals.pick_random())
	GlobalSignals.signal_core_goal_created(active_goal.instance_id)
	
func __on_goal_complete(goal_instance_id: String):
	if goal_instance_id == active_goal.instance_id:
		active_goal = Goal.load_goal(available_goals.pick_random())	
		GlobalSignals.signal_core_goal_created(active_goal.instance_id)
