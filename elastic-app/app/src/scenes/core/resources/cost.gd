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
	var aux_resources: AuxilliaryResources = AuxilliaryResources.new(source, target)
	for resource in requirements.keys():
		
		var aux_satisfy = aux_resources.__can_satisfy_requirement(resource, requirements[resource])
		if aux_satisfy:
			continue
		
		if not __can_satisfy_requirement(resource, requirements[resource]):
			return false
	return true

# Subtracts the requirements from the resources.  
func satisfy(source: Entity, target: Entity) -> bool:
	if not can_satisfy(source, target):
		printerr("Failed to satisfy costs.  Need to emit a signal here.")
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
func get_energy_color() -> Air.AirColor:		
	if requirements.has(Air.AirColor.RED):
		return Air.AirColor.RED
	if requirements.has(Air.AirColor.BLUE):
		return Air.AirColor.BLUE
	if requirements.has(Air.AirColor.ORANGE):
		return Air.AirColor.ORANGE
	
	return Air.AirColor.NONE
	#return requirements.get(GameResource.Type.RED_ENERGY, 0)			
	
func get_energy_cost() -> int:		
	if requirements.has(Air.AirColor.RED):
		return requirements[Air.AirColor.RED]
	if requirements.has(Air.AirColor.BLUE):
		return requirements[Air.AirColor.BLUE]
	if requirements.has(Air.AirColor.ORANGE):
		return requirements[Air.AirColor.ORANGE]
	
	return 0
	#return requirements.get(GameResource.Type.RED_ENERGY, 0)		
