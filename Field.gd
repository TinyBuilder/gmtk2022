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
var is_rolling = false
var rolling_dice = []
var dice_list = []
var is_making_move = true
var Dice = preload("res://Dice.tscn")
var Castle = preload("res://Castle.tscn")
var castles = []

func dice_roll(position) :
	is_rolling = true
	var dice = Dice.instance()
	rolling_dice.append(dice)
	add_child(dice)
	var dice_value = Global.rng.randi_range(1, 6)	
	dice.global_position = position 
	dice.roll(dice_value)
	$RollTimer.start()
	return dice_value

func make_move(cell, dice):
	dice.global_position = $TileMap.map_to_world(cell)

func _input(event):
	if event is InputEventMouseButton:
		# var pos = event.position
		# var cell = $TileMap.world_to_map($TileMap.to_local(pos))
		if event.pressed :
			print("click")
			dice_roll()
			# $TileMap.set_cellv(cell, 1)
		# else:
			#print("Mouse Unclick at: ", cell)
			#print("Highlight: ", $Highlight.global_position)
			# $TileMap.set_cellv(cell, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(board_width) :
		board_state.append([])
		for _y in range(board_height) :
			board_state[x].append(0) 
			# $TileMap.set_cellv(Vector2(x,y), 0)
	
	var i = 0
	while i < 6:
		var x = Global.rng.randi_range(1, board_width-2)
		var y = Global.rng.randi_range(1, board_height-2)
		if board_state[x][y] != 3:
			print("castle at: ",x," ",y)
			board_state[x][y] = 3
			var castle = Castle.instance()
			add_child(castle)
			castle.global_position = $TileMap.map_to_world(Vector2(x,y))
			castles.append(castle)
			i += 1

	#OS.window_size = Vector2(board_height * 64, board_width * 64)
	screen_center = OS.window_size / 2


	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var cursor_position = get_local_mouse_position()
	var cell = $TileMap.world_to_map($TileMap.to_local(cursor_position))
	$Highlight.global_position = $TileMap.map_to_world(cell)	
	#print("Cursor at: ", cursor_position)
	
func _on_RollTimer_timeout():
	is_rolling = false
