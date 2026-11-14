extends CanvasLayer

func _ready() -> void:
	
	visible = true
	get_tree().paused = true
#ngl, did need some AI help here
func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("Enter"):
		get_tree().paused = false # Unpause the main game
		queue_free() 
