extends Node

class_name GoalManager

var active_goal: Goal
const available_goals = ["spend_energy_1","play_cards_1","activate_buildings_1", "draw_cards_1", "destory_cards_1"]
var count: int = 0

func _init():
	GlobalSignals.core_goal_succeeded.connect(__on_goal_complete.bind(true))
	GlobalSignals.core_goal_failed.connect(__on_goal_complete.bind(false))
	GlobalSignals.core_begin_turn.connect(__on_begin_turn)
	
func __on_begin_turn():
	active_goal = Goal.load_goal(available_goals.pick_random())
	GlobalSignals.signal_core_goal_created(active_goal.instance_id)
	
func __on_goal_complete(goal_instance_id: String, success: bool):
	if goal_instance_id == active_goal.instance_id:
		if success:
			count = count + 1
		
		if count >= StaticData.get_int("goals_before_boss"):
			active_goal = Goal.load_goal("boss_1")	
		else:
			active_goal = Goal.load_goal(available_goals.pick_random())	
		GlobalSignals.signal_core_goal_created(active_goal.instance_id)

		
