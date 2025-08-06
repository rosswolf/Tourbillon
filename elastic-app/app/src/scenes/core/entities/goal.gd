extends Entity
class_name Goal
static func _get_type_string():
	return "Goal"

var reward: MoveDescriptorEffect
var text: String

var before_n_ticks: int = -1


var __achieve_bound 
var __achieve: Achieve
var achieve: Achieve:
	get(): return __achieve
	set(value): 
		if __achieve != null:
			__disconnect_achieve()
			
		__achieve = value
		__connect_achieve()

func __connect_achieve():
	__achieve_bound = __on_signal.bind(__achieve)
	GlobalSignals.connect(__achieve.signal_name, __achieve_bound)
		
func __disconnect_achieve():
	GlobalSignals.disconnect(__achieve.signalname, __achieve_bound)
	__achieve_bound = null

func __on_signal(amount: int, achieve: Achieve):
	if achieve.comparator == Comparator.EQUALS:
		if amount == achieve.target:
			__apply_reward()
	elif achieve.comparator == Comparator.LESS_THAN:
		if amount < achieve.target:
			__apply_reward()
	elif achieve.comparator == Comparator.GREATER_THAN:
		if amount > achieve.target:
			__apply_reward()
	elif achieve.comparator == Comparator.GREATER_THAN_OR_EQUALS:
		if amount >= achieve.target:
			__apply_reward()
	elif achieve.comparator == Comparator.LESS_THAN_OR_EQUALS:
		if amount <= achieve.target:
			__apply_reward()
	return
	
func __apply_reward():
	reward.activate(self)
	__disconnect_achieve()
	GlobalSignals.signal_core_goal_succeeded(self.instance_id)

func _get_type() -> Entity.EntityType:
	return Entity.EntityType.GOAL
	
func _generate_instance_id() -> String:
	return "goal_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func _requires_template_id() -> bool:
	return false

enum Comparator {
	UNKNOWN,
	EQUALS,
	LESS_THAN,
	GREATER_THAN,
	LESS_THAN_OR_EQUALS,
	GREATER_THAN_OR_EQUALS
}	
	
class Achieve:
	var signal_name: String
	var comparator: Comparator = Comparator.UNKNOWN
	var target: int
	
class GoalBuilder extends Entity.EntityBuilder:
	var __text: String		
	var __reward: MoveDescriptorEffect
	var __before_n_ticks: int = -1
	var __achieve: Achieve
			
	func with_text(text_in: String) -> GoalBuilder:
		__text = text_in
		return self
	
	func with_reward(reward_in: String) -> GoalBuilder:
		__reward = MoveDescriptorEffect.new(reward_in)
		return self
		
	func with_achieve(achieve_in: String) -> GoalBuilder:
		
		const splitters: Array[String] = ["==", ">=", "<=", ">", "<"]
		
		var achieve = Achieve.new()
		for splitter in splitters:
			if achieve_in.contains(splitter):
				var parts = achieve_in.split(splitter)
				if parts.size() != 2:
					assert(false, "unexpected achieve string " + achieve_in)
					return self
				else:
					achieve.signal_name = parts[0]
					achieve.target = int(parts[1])
				if splitter == "==":
					achieve.comparator = Comparator.EQUALS
				elif splitter == ">=":
					achieve.comparator = Comparator.GREATER_THAN_OR_EQUALS
				elif splitter == "<=":
					achieve.comparator = Comparator.LESS_THAN_OR_EQUALS
				elif splitter == ">":
					achieve.comparator = Comparator.GREATER_THAN
				elif splitter == "<":
					achieve.comparator = Comparator.LESS_THAN
				else:
					assert(false, "unexpected splitter " + splitter)
				
				__achieve = achieve
				return self
		
		assert(false, "Didnt find splitter in achive_in: " + achieve_in)
		return self
	
	func with_before_n_ticks(ticks_in: int) -> GoalBuilder:
		__before_n_ticks = ticks_in
		return self
		
	func build() -> Goal:
		var goal = Goal.new()
		super.build_entity(goal)
		goal.achieve == __achieve
		goal.before_n_ticks = __before_n_ticks
		goal.reward = __reward
		goal.text = __text
		return goal

static func load_goal(goal_template_id: String) -> Goal:
	var goal_data = StaticData.goals_data.get(goal_template_id)
	if goal_data == null:
		assert(false, "Goal template not found: " + goal_template_id)
		return null
	
	var builder = Goal.GoalBuilder.new()
	
	builder.with_template_id(goal_template_id)
	#builder.with_display_name(goal_data.get("display_name"))
	builder.with_text(goal_data.get("text"))
	builder.with_reward(goal_data.get("reward"))
	builder.with_achieve(goal_data.get("achieve"))
	builder.with_before_n_ticks(int(goal_data.get("before_n_ticks", -1)))
	
	# Set starting stats

	return builder.build()
