
extends AnimatedSprite2D

@export var speed: float = 60.0

var running = false
var controllable = false
var route = "go"
var start_position: Vector2
var route_distance = 0.0

func _ready():
	start_position = position

func start_route():
	running = true
	controllable = false
	route_distance = 0.0

	var routes = ["go", "slant", "in", "out"]
	route = routes.pick_random()

	if sprite_frames != null:
		play()

func _process(delta):
	if controllable:
		var direction = Vector2.ZERO

		if Input.is_key_pressed(KEY_W):
			direction.y -= 1
		if Input.is_key_pressed(KEY_S):
			direction.y += 1
		if Input.is_key_pressed(KEY_A):
			direction.x -= 1
		if Input.is_key_pressed(KEY_D):
			direction.x += 1

		if direction.length() > 0:
			position += direction.normalized() * speed * delta

	elif running:
		route_distance += speed * delta

		match route:
			"go":
				position.x += speed * delta

			"slant":
				position += Vector2(speed, -speed * 0.65) * delta

			"in":
				if route_distance < 120:
					position.x += speed * delta
				else:
					position.y -= speed * delta

			"out":
				if route_distance < 120:
					position.x += speed * delta
				else:
					position.y += speed * delta

func catch_ball():
	running = false
	controllable = true

func reset_route():
	running = false
	controllable = false
	route_distance = 0.0
	position = start_position
	stop()
