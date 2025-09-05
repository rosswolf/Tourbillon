extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignals.core_start_countdown.connect(__on_countdown_started)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func __on_countdown_started() -> void:
	#TODO: add in a countdown on the screen

	var delay: int = StaticData.get_int("countdown_delay")
	await get_tree().create_timer(delay).timeout

	GlobalGameManager.periodic.start_default_periodics()
