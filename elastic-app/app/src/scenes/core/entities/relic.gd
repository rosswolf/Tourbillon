extends Entity
class_name Relic
static func _get_type_string():
	return "Relic"

var description: String
var image_name: String
var starting_value: String

func __generate_instance_id() -> String:
	return "relic_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

static func load_relic(relic_template_id: String) -> Relic:
	var relic_data = StaticData.relic_data.get(relic_template_id)
	if relic_data == null:
		assert(false, "Relic template not found: " + relic_template_id)
		return null

	var builder = Relic.RelicBuilder.new()
	builder.with_template_id(relic_template_id)
	builder.with_display_name(relic_data.get("display_name"))
	builder.with_description(relic_data.get("description"))
	builder.with_image_name(relic_data.get("image_name"))
	builder.with_starting_value(str(int(relic_data.get("starting_value"))))
	return builder.build()

class RelicBuilder extends Entity.EntityBuilder:
	var __description: String
	var __image_name: String
	var __starting_value: String

	func with_description(description: String) -> RelicBuilder:
		__description = description
		return self

	func with_image_name(image_name: String) -> RelicBuilder:
		__image_name = image_name
		return self

	func with_starting_value(value: String) -> RelicBuilder:
		__starting_value = value
		return self


	func build() -> Relic:
		var relic: Relic = Relic.new()
		super.build_entity(relic)
		relic.description = __description
		relic.image_name = __image_name
		relic.starting_value = __starting_value
		return relic
