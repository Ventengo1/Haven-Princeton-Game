extends AnimatedSprite2D

var speed: float = 65.0
var start_position: Vector2

var assigned_receiver: Node2D = null
var ball_carrier: Node2D = null
var defending: bool = false

@export var tackle_distance: float = 24.0

func _ready():
	start_position = global_position

func start_defense(receiver: Node2D):
	print("-> Defender: Defense started, tracking receiver:", receiver.name if receiver else "None")
	assigned_receiver = receiver
	ball_carrier = null
	speed = randf_range(50.0, 80.0)
	defending = true
	# play()

func set_ball_carrier(target: Node2D):
	print("-> Defender: Ball carrier locked! Target:", target.name if target else "None")
	ball_carrier = target

func reset_defense():
	defending = false
	assigned_receiver = null
	ball_carrier = null
	global_position = start_position
	# stop()

func _process(delta):
	if not defending:
		return

	var target: Node2D = null

	if is_instance_valid(ball_carrier):
		target = ball_carrier
	elif is_instance_valid(assigned_receiver):
		target = assigned_receiver

	if target != null:
		global_position = global_position.move_toward(
			target.global_position,
			speed * delta
		)
		
		
		if global_position.distance_to(target.global_position) <= tackle_distance:
			print("-> Defender: Tackled target!")
			
			
			
