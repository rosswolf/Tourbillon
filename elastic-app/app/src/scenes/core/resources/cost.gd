extends Resource

# Costs cannot be satisfied unless you can fulfill all of the requirements
class_name Cost

var requirements : Dictionary[GameResource.Type, int]

class AuxilliaryResources:
	func _init(source_in: Entity, target_in: Entity):
		# This might cause issues in the future if we mix resource types between card modalities. 
		# Right now, a card just provides its resources always, not conditionally based on how it is being affectuated. 
		# Specifically, if you consume a card that provides a RED_TRIGGER, or if you activate a building with a card,
		# it would currently provide the RED_TRIGGER for both (activation of building, and consumption). 
		# This wont cause issues if we never mix resource types across modalities. 
		var card: Card = source_in as Card
		if card:
			resources[card.trigger_resource] = resources.get(card.trigger_resource, 0) + 1
	
	func __can_satisfy_requirement(requirement: GameResource.Type, amount):
		return resources.get(requirement, 0) >= amount
		
	func __satisfy_requirement(requirement: GameResource.Type, amount) -> bool:
		if not __can_satisfy_requirement(requirement, amount):
			return false
		else:
			resources[requirement] = resources.get(requirement, 0) - amount
			return true
	
	var resources: Dictionary[GameResource.Type, int] = {}


func _init(resources: Dictionary[GameResource.Type, int]):
	requirements = resources.duplicate()

func can_satisfy(source: Entity, target: Entity) -> bool:
	return get_unsatisfied_resources(source, target).size() == 0
	
func signal_unsatisfied(source: Entity, target: Entity):
	var unsatisfied_types: Array[GameResource.Type] = get_unsatisfied_resources(source, target)
	for type in unsatisfied_types:
		GlobalSignals.signal_core_missing_resource(type)
	
func get_unsatisfied_resources(source: Entity, target: Entity) -> Array[GameResource.Type]:
	var unsatisfied_types: Array[GameResource.Type] = []
	
	var aux_resources: AuxilliaryResources = AuxilliaryResources.new(source, target)
	for resource in requirements.keys():
		
		var aux_satisfy = aux_resources.__can_satisfy_requirement(resource, requirements[resource])
		if aux_satisfy:
			continue
		
		if not __can_satisfy_requirement(resource, requirements[resource]):
			unsatisfied_types.append(resource)
			
	return unsatisfied_types
	

# Subtracts the requirements from the resources.  
func satisfy(source: Entity, target: Entity) -> bool:
	if not can_satisfy(source, target):
		signal_unsatisfied(source, target)
		return false
		
	var aux_resources: AuxilliaryResources = AuxilliaryResources.new(source, target)	
	for resource in requirements.keys():
		
		var aux_satisfy = aux_resources.__satisfy_requirement(resource, requirements[resource])
		if aux_satisfy:
			continue
		var local_satisfy = __satisfy_requirement(resource, requirements[resource])
		if not local_satisfy:
			return false
			
	return true
		
func __satisfy_requirement(resource_type: GameResource.Type, amount: int) -> bool:
	if amount <= 0:
		return true
	if resource_type == GameResource.Type.UNKNOWN:
		printerr("Type.UNKNOWN in requirements. ")
		return false
	var resource_accesor = GameResource.ResourceAccessor.new()
	resource_accesor.decrement(resource_type, amount)
	return true

func __can_satisfy_requirement(resource_type: GameResource.Type, amount: int) -> bool:
	if amount <= 0:
		return true
	if resource_type == GameResource.Type.UNKNOWN:
		printerr("Type.UNKNOWN in requirements. ")
		return false
	var resource_accesor = GameResource.ResourceAccessor.new()
	return resource_accesor.get_count(resource_type) >= amount
	#
func get_energy_color() ->  GameResource.Type:		
	# Check new force resources
	if requirements.has(GameResource.Type.HEAT):
		return GameResource.Type.HEAT
	if requirements.has(GameResource.Type.PRECISION):
		return GameResource.Type.PRECISION
	if requirements.has(GameResource.Type.MOMENTUM):
		return GameResource.Type.MOMENTUM
	if requirements.has(GameResource.Type.BALANCE):
		return GameResource.Type.BALANCE
	if requirements.has(GameResource.Type.ENTROPY):
		return GameResource.Type.ENTROPY
	# Legacy support
	if requirements.has(GameResource.Type.PURPLE_ENERGY):
		return GameResource.Type.PURPLE_ENERGY
	if requirements.has(GameResource.Type.BLUE_ENERGY):
		return GameResource.Type.BLUE_ENERGY
	if requirements.has(GameResource.Type.GREEN_ENERGY):
		return GameResource.Type.GREEN_ENERGY
	
	return GameResource.Type.NONE
	
func get_energy_cost() -> int:		
	# Check new force resources
	if requirements.has(GameResource.Type.HEAT):
		return requirements[GameResource.Type.HEAT]
	if requirements.has(GameResource.Type.PRECISION):
		return requirements[GameResource.Type.PRECISION]
	if requirements.has(GameResource.Type.MOMENTUM):
		return requirements[GameResource.Type.MOMENTUM]
	if requirements.has(GameResource.Type.BALANCE):
		return requirements[GameResource.Type.BALANCE]
	if requirements.has(GameResource.Type.ENTROPY):
		return requirements[GameResource.Type.ENTROPY]
	# Legacy support
	if requirements.has(GameResource.Type.PURPLE_ENERGY):
		return requirements[GameResource.Type.PURPLE_ENERGY]
	if requirements.has(GameResource.Type.BLUE_ENERGY):
		return requirements[GameResource.Type.BLUE_ENERGY]
	if requirements.has(GameResource.Type.GREEN_ENERGY):
		return requirements[GameResource.Type.GREEN_ENERGY]
	
	return 0		
