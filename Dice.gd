extends Node2D 


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var result = 0
var roll_progress = 0
var last_result = 0
var fast_roll = 1/30
onready var timer = $Timer
onready var sprite = $AnimatedSprite

func roll(determined_result) :
	print("rolling")
	roll_progress = 1
	result = determined_result

func set_face(determined_result):
	sprite.frame = determined_result - 1

# func _input(event):
# 	if event is InputEventMouseButton:
# 		if event.pressed and roll_progress == 0:
# 			roll(2)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if roll_progress < 1:
		return	
	
	roll_progress += 1
	
	if roll_progress > 30:
		if (roll_progress % 3) != 0:
			return
	
	var current_face = Global.rng.randi_range(1, 6)
	if current_face == last_result:
		current_face += 1
		if current_face > 6:
			current_face = 1
	last_result = current_face
	sprite.frame = current_face - 1

	if roll_progress > 60:
		roll_progress = 0
		sprite.frame = result - 1
