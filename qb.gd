extends Node2D

@export var sack_time: float = 4.5
@export var touchdown_x: float = 1100.0
@export var pass_speed: float = 300.0

@onready var qb = $QB
@onready var ball = $Ball
@onready var status_label = $UI/StatusLabel

@onready var receivers = [
	$Player/WR1,
	$Player/WR2,
	$Player/WR3,
	$Player/TE1,
	$Player/RB
]

var phase = "ready"
var sack_timer = 0.0
var play_tween: Tween

func _ready():
	ball.global_position = qb.global_position
	status_label.text = "PRESS SPACE TO SNAP"

func _process(delta):
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

	for receiver in receivers:
		receiver.reset_route()

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

# Predict where the receiver will be
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

	# Move receiver to the catch location
	target.global_position = predicted_position

	for receiver in receivers:
		receiver.running = false
		receiver.controllable = false

	ball.global_position = predicted_position
	target.catch_ball()

	phase = "control"

	status_label.text = "CATCH! USE WASD"

func sack():
	phase = "over"

	for receiver in receivers:
		receiver.running = false

	ball.global_position = qb.global_position

	status_label.text = "SACKED! PRESS SPACE TO RETRY"

func check_touchdown():
	for receiver in receivers:
		if receiver.controllable:
			if receiver.global_position.x >= touchdown_x:
				phase = "over"
				status_label.text = "TOUCHDOWN! PRESS SPACE TO PLAY AGAIN"
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
