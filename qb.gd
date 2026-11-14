extends Node2D #file for Joe the GOATTTTT

@export var sack_time: float = 4.5
@export var touchdown_x: float = 1100.0
@export var pass_speed: float = 300.0

@onready var qb = $QB
@onready var ball = $Ball
@onready var status_label = $UI/StatusLabel

@onready var receivers = [
	$Player/WR3,
	$Player/WR1,
	$Player/WR2,
	$Player/TE1,
	$Player/RB
]

@onready var defenders = [
	$Defender/CB5,
	$Defender/CB2,
	$Defender/CB1,
	$Defender/CB3,
	$Defender/CB4
]

var phase = "ready"
var sack_timer = 0.0
var play_tween: Tween
var number_labels: Array[Label] = []
var ball_carrier: Node2D = null


var line_of_scrimmage_x: float = 0.0
var initial_qb_x: float = 0.0

var receiver_y_coords: Array[float] = []
var defender_offsets: Array[Vector2] = []

func _ready():
	initial_qb_x = qb.global_position.x
	line_of_scrimmage_x = initial_qb_x 
	ball.global_position = qb.global_position
	status_label.text = "PRESS SPACE TO SNAP"

	
	receivers.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
	defenders.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)

	for r in receivers:
		receiver_y_coords.append(r.global_position.y)

	for d in defenders:
		defender_offsets.append(d.global_position - qb.global_position)

	for defender in defenders:
		defender.tackled.connect(tackle)

	
	var label_layer = Node2D.new()
	label_layer.name = "ReceiverNumberLayer"
	label_layer.z_index = 100
	add_child(label_layer)

	for i in range(receivers.size()):
		var label = Label.new()
		label.text = str(i + 1)
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color(1, 1, 0, 1))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 4)
		label_layer.add_child(label)
		number_labels.append(label)

func _process(delta):
	
	for i in range(receivers.size()):
		if i < number_labels.size() and is_instance_valid(receivers[i]):
			number_labels[i].global_position = receivers[i].global_position + Vector2(-8, -45)

	
	if is_instance_valid(ball_carrier) and (phase == "control" or phase == "over"):
		ball.global_position = ball_carrier.global_position + Vector2(8, 0)

	if phase == "running":
		sack_timer += delta

		if sack_timer >= sack_time:
			sack()

	if phase == "control":
		check_touchdown()

func _unhandled_input(event):
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	if event.keycode == KEY_SPACE:
		if phase == "ready" or phase == "over":
			start_play()

	if phase == "running":
		match event.keycode:
			KEY_1:
				throw_ball(0)
			KEY_2:
				throw_ball(1)
			KEY_3:
				throw_ball(2)
			KEY_4:
				throw_ball(3)
			KEY_5:
				throw_ball(4)

func start_play():
	if play_tween and play_tween.is_running():
		play_tween.kill()

	ball_carrier = null

	for receiver in receivers:
		receiver.reset_route()
		receiver.running = false
		receiver.controllable = false


	qb.global_position.x = line_of_scrimmage_x
	
	for i in range(receivers.size()):
		receivers[i].global_position = Vector2(line_of_scrimmage_x, receiver_y_coords[i])

	for i in range(defenders.size()):
		defenders[i].global_position = Vector2(line_of_scrimmage_x, qb.global_position.y) + defender_offsets[i]
		if i < receivers.size():
			defenders[i].start_defense(receivers[i])
		else:
			defenders[i].reset_defense()

	ball.global_position = qb.global_position

	sack_timer = 0.0
	phase = "running"

	for receiver in receivers:
		receiver.start_route()

	status_label.text = "PLAY! PRESS 1-5 TO PASS"

func throw_ball(index):
	if phase != "running":
		return

	if index < 0 or index >= receivers.size():
		return

	phase = "passing"

	var target = receivers[index]

	status_label.text = "PASSING TO " + str(index + 1)

	var distance = ball.global_position.distance_to(
		target.global_position
	)

	var travel_time = max(distance / pass_speed, 0.15)

	var predicted_position = predict_receiver_position(
		target,
		travel_time
	)

	play_tween = create_tween()

	play_tween.tween_property(
		ball,
		"global_position",
		predicted_position,
		travel_time
	)

	await play_tween.finished

	if phase != "passing":
		return

	target.global_position = predicted_position

	for receiver in receivers:
		receiver.running = false
		receiver.controllable = false

	ball_carrier = target
	ball.global_position = target.global_position + Vector2(8, 0)
	target.catch_ball()

	for defender in defenders:
		defender.set_ball_carrier(target)

	phase = "control"

	status_label.text = "CATCH! USE WASD"

func tackle():
	if phase != "control":
		return

	phase = "over"

	# we emoved line_of_scrimmage_x update here, so plays always reset to the start line
	# was giving us ton of errors so did this

	for receiver in receivers:
		receiver.running = false
		receiver.controllable = false

	for defender in defenders:
		defender.defending = false
		if defender.sprite_frames != null:
			defender.stop()

	status_label.text = "TACKLED! PRESS SPACE TO SNAP"

func sack():
	phase = "over"
	ball_carrier = null

	for receiver in receivers:
		receiver.running = false

	for defender in defenders:
		defender.reset_defense()

	ball.global_position = qb.global_position

	status_label.text = "SACKED! PRESS SPACE TO RETRY"

func check_touchdown():
	for receiver in receivers:
		if receiver.controllable:
			if receiver.global_position.x >= touchdown_x:
				phase = "over"
				for defender in defenders:
					defender.defending = false
				
				status_label.text = "TOUCHDOWN! You WINNNNN! PRESS SPACE TO PLAY AGAIN"
				return

func predict_receiver_position(receiver, travel_time: float) -> Vector2:
	var future_position = receiver.global_position

	if receiver.running:
		match receiver.route:
			"go":
				future_position.x += receiver.speed * travel_time

			"slant":
				future_position += Vector2(
					receiver.speed,
					-receiver.speed * 0.65
				) * travel_time

			"in":
				future_position += Vector2(
					0,
					-receiver.speed
				) * travel_time

			"out":
				future_position += Vector2(
					0,
					receiver.speed
				) * travel_time

	return future_position
