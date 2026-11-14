extends AnimatedSprite2D

signal tackled

@export var speed: float = 45.0 
@export var tackle_distance: float = 24.0

var start_position: Vector2
var assigned_receiver: Node2D = null
var ball_carrier: Node2D = null
var defending: bool = false

var is_busted_coverage: bool = false
var reaction_timer: float = 0.0 

func _ready():
	start_position = global_position

func start_defense(receiver: Node2D):
	assigned_receiver = receiver
	ball_carrier = null
	
	##fast as hell before
	speed = randf_range(30.0, 50.0)
	
	defending = true
	reaction_timer = 0.3 # 0.3 second delay before they start running, were too good so gotta change u know
	
	
	is_busted_coverage = (randf() < 0.70)
	
	if sprite_frames != null:
		play()

func set_ball_carrier(target: Node2D):
	ball_carrier = target
	is_busted_coverage = false

func reset_defense():
	defending = false
	assigned_receiver = null
	ball_carrier = null
	global_position = start_position
	is_busted_coverage = false
	reaction_timer = 0.0
	if sprite_frames != null:
		stop()

func _process(delta):
	if not defending:
		return


	if reaction_timer > 0:
		reaction_timer -= delta
		return

	var target: Node2D = null

	if is_instance_valid(ball_carrier):
		target = ball_carrier
	elif is_instance_valid(assigned_receiver):
		target = assigned_receiver

	if target != null:
		var current_speed = speed

		# If they busted coverage, they crawl at 20% speed instead
		if is_busted_coverage and not is_instance_valid(ball_carrier):
			current_speed *= 0.20

		global_position = global_position.move_toward(
			target.global_position,
			current_speed * delta
		)

		if is_instance_valid(ball_carrier) and global_position.distance_to(ball_carrier.global_position) <= tackle_distance:
			tackled.emit()
