extends Node
class_name RelicManager

var __relics: Dictionary[String, Relic] = {}


func add_relic(relic_template_id: String) -> Relic:
	var r = Relic.load_relic(relic_template_id)
	__relics[relic_template_id] = r
	return r

func has_relic(relic_template_id: String) -> bool:
	return __relics.has(relic_template_id)
