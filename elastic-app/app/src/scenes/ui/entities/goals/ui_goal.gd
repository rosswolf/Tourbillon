extends UiEntity

class_name UiGoal

func _ready() -> void:
	GlobalSignals.core_goal_failed.connect(__on_core_goal_failed)
	GlobalSignals.core_goal_succeeded.connect(__on_core_goal_succeeded)
	
func set_entity_data(entity: Entity) -> void:
	await super.set_entity_data(entity)
	var goal: Goal = __entity as Goal
	if goal == null:
		assert(false, "cant parse entity as a goal")
		
	%GoalText.text = goal.text
	if goal.before_n_ticks != -1:
		%Timer.wait_time = goal.before_n_ticks
		%Timer.timeout.connect(__on_timeout)
		%Timer.start()
		
	
func pct(numerator: float, denominator: float):
	if denominator <= 0.001:
		return 0.0
	else:
		return 100.0 * numerator / denominator	

func __on_timeout() -> void:
	var goal: Goal = __entity as Goal
	if goal == null:
		assert(false, "cant parse entity as a goal")
	GlobalSignals.signal_core_goal_failed(goal.instance_id)		
		
func _process(delta: float) -> void:
	var goal: Goal = __entity as Goal
	if goal == null:
		assert(false, "cant parse entity as a goal")
	%ProgressBar.value = pct(%Timer.time_left, goal.before_n_ticks)

func __on_core_goal_failed(goal_instance_id: String) -> void:
	var goal: Goal = __entity as Goal
	if goal == null:
		assert(false, "cant parse entity as a goal")
	if goal.instance_id == goal_instance_id:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate", Color.RED, 0.5)
		tween.chain().tween_property(self, "modulate:a", 0.0, 0.7)
		tween.tween_callback(queue_free)
	
func __on_core_goal_succeeded(goal_instance_id: String) -> void:
	var goal: Goal = __entity as Goal
	if goal == null:
		assert(false, "cant parse entity as a goal")
	if goal.instance_id == goal_instance_id:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate", Color.AQUAMARINE, 0.5)
		tween.chain().tween_property(self, "modulate:a", 0.0, 0.7)
		tween.tween_callback(queue_free)
