extends Effect

class_name OneTimeEffect

# the raw function, unbound and unmodified. 
var __base_f: Callable
var parameters: Dictionary 

var __valid_source_types: Array
var __valid_target_types: Array

var __effect_template_id: String
var effect_template_id: String:
	get:
		return __effect_template_id

var __cost: Cost
var cost: Cost:
	get:
		return __cost
		
func _init(template_id: String,  params: Dictionary, cost: Cost = null) -> void:
	var internal_effect: Effect.InternalEffect = Effect.effect_map.get(template_id)
	if not internal_effect:
		assert(0, "missing effect with template id " + template_id)	
		
	__effect_template_id = template_id
	__base_f = internal_effect.__f
	__valid_source_types = internal_effect.__valid_source_types
	__valid_target_types = internal_effect.__valid_target_types
	__cost = cost
	parameters = params
	effect_name = template_id

func activate(source: Entity) -> bool:
	#print("Taking effect " + __effect_template_id)
	
	# TODO(virtual) if we decide to have cards carry effects onto the things they
	# activate.. then unpack them here and put them in paramters.  
	
	if source is Card:
		parameters["card"] = source
		return __base_f.call(GlobalGameManager.hero, parameters)
	elif source is Goal:
		return __base_f.call(source, parameters)
	else:
		assert(false, "Unexpected source type")
		return false


func __is_valid_source(source: Entity) -> bool:
	#if _effect_type != EffectType.ACTIVATABLE:
		#return false
	var satisfy_target_requirments = Effect.entity_in_types(source, __valid_source_types)
	if not satisfy_target_requirments:
		return false
	else:	
		return true
		
func __is_valid_target(source: Entity) -> bool:
	#if _effect_type != EffectType.ACTIVATABLE:
		#return false
	var satisfy_target_requirments = Effect.entity_in_types(source, __valid_target_types)
	if not satisfy_target_requirments:
		return false
	else:	
		return true
	
func __could_satisfy_costs(source: Entity, target: Entity) -> bool:
	if cost == null:
		return true
	else:
		return cost.can_satisfy(source, target)
		
func __execute_satisfy_costs(source: Entity, target: Entity) -> bool:
	if cost == null:
		return true
	else:
		return cost.satisfy(source, target)
