extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var player_dice = 0
var opponent_dice = 0
var board_height = 15
var board_width = 15
var board_state = []
var turn = 0
var screen_center = Vector2(0,0)
var dice_rolling = false
var Dice = preload("res://Dice.tscn")
onready var tilemap = $TileMap
onready var highlight = $Highlight

func dice_roll() :
	var dice = Dice.instance()
	add_child(dice)
	var dice_value = Global.rng.randi_range(1, 6)	
	dice.global_position = screen_center
	dice.roll(dice_value)
	return dice_value

func _input(event):
	if event is InputEventMouseButton:
		# var pos = event.position
		# var cell = tilemap.world_to_map(tilemap.to_local(pos))
		if event.pressed :
			print("click")
			dice_roll()
			# tilemap.set_cellv(cell, 1)
		# else:
			#print("Mouse Unclick at: ", cell)
			#print("Highlight: ", highlight.global_position)
			# tilemap.set_cellv(cell, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(board_width) :
		board_state.append([])
		for y in range(board_height) :
			board_state[x].append(0) 
			tilemap.set_cellv(Vector2(x,y), 0)

	OS.window_size = Vector2(board_height * 64, board_width * 64)
	screen_center = OS.window_size / 2


	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var cursor_position = get_local_mouse_position()
	var cell = tilemap.world_to_map(tilemap.to_local(cursor_position))
	highlight.global_position = tilemap.map_to_world(cell)	
	#print("Cursor at: ", cursor_position)
	
	
