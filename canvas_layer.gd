extends CanvasLayer

func _ready() -> void:
	# Make sure the intro screen is visible and pause the game behind it
	visible = true
	get_tree().paused = true

func _unhandled_input(event: InputEvent) -> void:
	# "ui_accept" is mapped to the Enter key (and Spacebar) by default in Godot
	if event.is_action_pressed("ui_accept"):
		get_tree().paused = false # Unpause the main game
		queue_free() # Delete the black screen and text
