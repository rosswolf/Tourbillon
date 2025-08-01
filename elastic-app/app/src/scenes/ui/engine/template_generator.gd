extends Node
class_name TemplateGenerator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

static func generate_template(engine_template: EngineTemplate) -> void:
	# TODO: add logic here that determines how to generate the template
	# i.e. does each class have a default template? is random templates a setting?
	generate_knight_default_template(engine_template)
	
static func generate_random_template(engine_template: EngineTemplate) -> void:
	pass

static func generate_knight_default_template(engine_template: EngineTemplate) -> void:	
	# Start Knight-specific skill already slotted
	var default_slot = engine_template.get_slot(2,0)
	default_slot.attach_card(GlobalGameManager.instance_catalog.get_instance("knight_default"),)
	GlobalGameManager.library.move_card_to_zone2("knight_default", Library.Zone.DEFAULT_LIBRARY, Library.Zone.SLOTTED)

	# Connections
	engine_template.add_one_way_connection(2,0,1,0)
	engine_template.add_one_way_connection(1,0,0,0)
	engine_template.add_two_way_connection(1,0,1,1)
	
	engine_template.add_one_way_connection(2,1,1,1)
	
	engine_template.add_one_way_connection(2,2,1,2)
	engine_template.add_one_way_connection(2,2,2,3)
	engine_template.add_one_way_connection(1,2,0,2)
	engine_template.add_one_way_connection(1,2,1,3)
	engine_template.add_one_way_connection(0,2,0,3)
	engine_template.add_one_way_connection(0,2,0,1)
	
	engine_template.add_one_way_connection(2,4,1,4)
	engine_template.add_one_way_connection(2,4,2,3)
	engine_template.add_one_way_connection(1,4,0,4)
