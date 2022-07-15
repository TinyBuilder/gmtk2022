extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var dice = 0
var opponent_dice = 0
var board_height = 15
var board_width = 15
var board_state = []
onready var tilemap = $TileMap
onready var highlight = $Highlight

func _input(event):
	if event is InputEventMouseButton:
		var pos = event.position
		var cell = tilemap.world_to_map(tilemap.to_local(pos))
		if event.pressed && dice > 0:
			#print("Mouse Click at: ", cell)
			tilemap.set_cellv(cell, 1)
		else:
			#print("Mouse Unclick at: ", cell)
			#print("Highlight: ", highlight.global_position)
			tilemap.set_cellv(cell, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(board_width) :
		board_state.append([])
		for y in range(board_height) :
			board_state[x].append(0) 
			tilemap.set_cellv(Vector2(x,y), 0)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var cursor_position = get_local_mouse_position()
	var cell = tilemap.world_to_map(tilemap.to_local(cursor_position))
	highlight.global_position = tilemap.map_to_world(cell + Vector2(-1,1))	
	#print("Cursor at: ", cursor_position)
	
	
