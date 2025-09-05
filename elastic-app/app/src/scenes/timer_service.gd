# TimerService.gd
extends Node

func create_timer(duration: float) -> SceneTreeTimer:
	if not is_inside_tree():
		assert(false, "Timer service must be on the scene tree")
	return get_tree().create_timer(duration, false)

func create_unpauseable_timer(duration: float) -> SceneTreeTimer:
	if not is_inside_tree():
		assert(false, "Timer service must be on the scene tree")
	return get_tree().create_timer(duration)
