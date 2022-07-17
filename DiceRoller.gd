extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var is_rolling = false
export var is_starter = false
var dice1_done = false
var dice2_done = false
var result = 0
var automate = false
onready var dice1 = $DiceContainer1/CollisionShape2D/Dice1
onready var dice2 = $DiceContainer2/CollisionShape2D/Dice2

func roll( auto = false):
	if auto:
		automate = true

	is_rolling = true
	dice1.roll(Global.rng.randi_range(1,6))
	dice2.roll(Global.rng.randi_range(1,6))

# Called when the node enters the scene tree for the first time.
func _ready():
	if is_starter:
		roll()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if automate and not is_rolling:
		var pick = Global.rng.randi_range(1,2)
		if pick == 1:
			result = dice1.result
		else:
			result = dice2.result
		
		automate = false
		hide()

func _on_DiceContainer1_input_event(_viewport:Node, event:InputEvent, _shape_idx:int):
	if is_rolling or is_starter or automate:
		return
	
	if event is InputEventMouseButton:
		if event.pressed:
			result = dice1.result
			hide()

func _on_DiceContainer2_input_event(_viewport:Node, event:InputEvent, _shape_idx:int):
	if is_rolling or is_starter or automate:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			result = dice2.result
			hide()

func _on_Dice1_done():
	if dice2_done:
		is_rolling = false
		dice2_done = false
		dice1_done = false
		return

	dice1_done = true

func _on_Dice2_done():
	if dice1_done:
		is_rolling = false
		dice1_done = false
		dice2_done = false
		return
	
	dice2_done = true
