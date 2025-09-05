extends Control

var resources_containers: Dictionary[GameResource.Type, PanelContainer] = {}



func _ready() -> void:
	print("[DEBUG] [RevealedResourcesPanel] _ready() called")
	print("[DEBUG] [RevealedResourcesPanel] Panel visible: ", visible)
	print("[DEBUG] [RevealedResourcesPanel] Parent visible: ", get_parent().visible if get_parent() else "no parent")
	var resource_template: PanelContainer = %ResourceContainerTemplate
	print("[DEBUG] [RevealedResourcesPanel] Template found: ", resource_template != null)


	# Debug: Print all children to see what names actually exist
	print("[DEBUG] Template children:")
	for child in resource_template.get_children():
		print("[DEBUG]   ", child.name, " (", child.get_class(), ")")
		for grandchild in child.get_children():
			print("[DEBUG]     ", grandchild.name, " (", grandchild.get_class(), ")")
			for greatgrandchild in grandchild.get_children():
				print("[DEBUG]       ", greatgrandchild.name, " (", greatgrandchild.get_class(), ")")


	for resource_name in GameResource.Type.keys():
		var resource_type: GameResource.Type = GameResource.Type[resource_name]

		# Skip UNKNOWN and legacy resources from UI display
		if resource_type == GameResource.Type.UNKNOWN or resource_type == GameResource.Type.NONE:
			continue
		# Skip legacy time/energy resources
		if resource_name.ends_with("_TIME") or resource_name.ends_with("_ENERGY"):
			continue

		var specific_resource = resource_template.duplicate()

		var resource_label: Label = specific_resource.get_node("MarginContainer/HBoxContainer/ResourceLabel")
		var resource_amount: Label = specific_resource.get_node("MarginContainer/HBoxContainer/ResourceAmount")

		resource_label.text = resource_name + ":"
		resource_amount.text = "0"

		# Start hidden - will be shown when resource changes to non-zero
		specific_resource.visible = false

		resources_containers[resource_type] = specific_resource

		%RevealedResourceVbox.add_child(specific_resource)

	# Connect signal ONCE outside the loop
	print("[DEBUG] [RevealedResourcesPanel] Containers created: ", resources_containers.size())
	GlobalSignals.core_hero_resource_changed.connect(__on_resource_changed)
	print("[DEBUG] [RevealedResourcesPanel] Signal connected successfully")

func __update_label(container: PanelContainer, amount_text: String) -> void:
	var resource_amount: Label = container.get_node("MarginContainer/HBoxContainer/ResourceAmount")
	resource_amount.text = amount_text

func __on_resource_changed(changing_resource: GameResource.Type, new_amount: int) -> void:
	print("[DEBUG] [RevealedResourcesPanel] Resource changed: ", GameResource.Type.keys()[changing_resource], " = ", new_amount)
	var container: PanelContainer = resources_containers.get(changing_resource)
	if container == null:
		print("[RevealedResourcesPanel] ERROR: No container for resource type: ", changing_resource)
		assert(false, "unepected resource unhandled " + str(changing_resource))
		return

	__update_label(container, str(new_amount))

	if new_amount != 0:
		print("[DEBUG] [RevealedResourcesPanel] Making visible: ", GameResource.Type.keys()[changing_resource])
		resources_containers[changing_resource].visible = true
	else:
		print("[DEBUG] [RevealedResourcesPanel] Keeping hidden (amount is 0): ", GameResource.Type.keys()[changing_resource])
