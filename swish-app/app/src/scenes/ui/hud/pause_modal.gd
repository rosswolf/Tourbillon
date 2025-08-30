extends Control
class_name PauseModal

@onready var animation_player := $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func resume():
	hide()
	get_tree().paused = false 
	animation_player.play_backwards("blur")
	
func pause():
	show()	
	animation_player.play("blur")
	get_tree().paused = true


func _on_resume_pressed() -> void:
	resume()

func _on_quit_pressed() -> void:
	get_tree().quit()
