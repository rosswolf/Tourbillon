extends Control

var resources_containers: Dictionary[GameResource.Type, PanelContainer] = {}



func _ready():
	var resource_template: PanelContainer = %ResourceContainerTemplate
	
	
	# Debug: Print all children to see what names actually exist
	print("Template children:")
	for child in resource_template.get_children():
		print("  ", child.name, " (", child.get_class(), ")")
		for grandchild in child.get_children():
			print("    ", grandchild.name, " (", grandchild.get_class(), ")")
			for greatgrandchild in grandchild.get_children():
				print("      ", greatgrandchild.name, " (", greatgrandchild.get_class(), ")")
	
	
	for resource_name in GameResource.Type.keys():
		var resource_type: GameResource.Type = GameResource.Type[resource_name]
		
		var specific_resource = resource_template.duplicate()
		
		var resource_label: Label = specific_resource.get_node("MarginContainer/HBoxContainer/ResourceLabel")
		var resource_amount: Label = specific_resource.get_node("MarginContainer/HBoxContainer/ResourceAmount")
		
		resource_label.text = resource_name + ":"
		resource_amount.text = ""
		
		resources_containers[resource_type] = specific_resource
		
		%RevealedResourceVbox.add_child(specific_resource)
		
		GlobalSignals.core_hero_resource_changed.connect(__on_resource_changed)

func __update_label(container: PanelContainer, amount_text: String):
	var resource_amount: Label = container.get_node("MarginContainer/HBoxContainer/ResourceAmount")
	resource_amount.text = amount_text

func __on_resource_changed(changing_resource: GameResource.Type, new_amount: int):
	var container: PanelContainer = resources_containers.get(changing_resource)
	if container == null:
		assert(false, "unepected resource unhandled " + str(changing_resource))
		return	
	
	__update_label(container, str(new_amount))
	
	if new_amount != 0:
		print("Marking as visible resource: " + str(changing_resource))
		resources_containers[changing_resource].visible = true
	
