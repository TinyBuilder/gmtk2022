# Declare member variables here. Examples:
# var a = 2
# var b = "text"
extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var player_dice = 0
var opponent_dice = 0
var board_height = 15
var board_width = 15
var board_state = []
var cell_fills = []
var highlighted_path = []
var temporary_highlights = []
var remaining_paths = 0
var turn = 0
var screen_center = Vector2(0, 0)
var is_rolling = false
var active_dice
var move_step = 0
var last_dice_placement
var Castle = preload("res://Castle.tscn")
var FilledCell = preload("res://FilledCell.tscn")
var castles = []


# Called when the node enters the scene tree for the first time.
func _ready():
	for x in range(board_width):
		board_state.append([])
		cell_fills.append([])
		for _y in range(board_height):
			board_state[x].append(0)
			cell_fills[x].append(null)
			# $TileMap.set_cellv(Vector2(x,y), 0)

	var castle_coords = []
	var mapn = Global.rng.randi_range(0, 4)
	# print("Playing map: ", mapn)

	if mapn == 0:
		castle_coords = [[4, 2], [8, 3], [3, 6], [11, 8], [6, 11], [10, 12]]
	elif mapn == 1:
		castle_coords = [[3, 6], [8, 3], [11, 8], [6, 11], [7, 7]]
	elif mapn == 2:
		castle_coords = [[4, 4], [11, 3], [7, 5], [6, 9], [9, 10], [2, 11]]
	elif mapn == 3:
		castle_coords = [[2, 12], [3, 6], [8, 4], [7, 10], [12, 8], [13, 2]]
	else:
		castle_coords = [[2, 5], [7, 5], [12, 5], [2, 9], [7, 9], [12, 9]]

	for coord in castle_coords:
		var x = coord[0]
		var y = coord[1]
		board_state[x][y] = 3
		var castle = Castle.instance()
		add_child(castle)
		castle.global_position = $TileMap.map_to_world(Vector2(x, y)) + $TileMap.global_position
		castles.append(castle)

	turn = 1


func fill_cell(cell):
	board_state[cell.x][cell.y] = turn
	if cell_fills[cell.x][cell.y] == null:
		cell_fills[cell.x][cell.y] = FilledCell.instance()
		cell_fills[cell.x][cell.y].global_position = ($TileMap.map_to_world(cell))
		add_child(cell_fills[cell.x][cell.y])

	cell_fills[cell.x][cell.y].color(turn)


func get_adjacent(cell):
	var adjacent = [
		Vector2(cell.x, cell.y - 1),
		Vector2(cell.x + 1, cell.y - 1),
		Vector2(cell.x + 1, cell.y),
		Vector2(cell.x + 1, cell.y + 1),
		Vector2(cell.x, cell.y + 1),
		Vector2(cell.x - 1, cell.y + 1),
		Vector2(cell.x - 1, cell.y),
		Vector2(cell.x - 1, cell.y - 1)
	]

	return adjacent


func get_cardinals(cell):
	var cardinals = [
		Vector2(cell.x, cell.y - 1),
		Vector2(cell.x + 1, cell.y),
		Vector2(cell.x, cell.y + 1),
		Vector2(cell.x - 1, cell.y)
	]

	return cardinals


func get_neighbours(cell):
	var adjacent = get_adjacent(cell)

	var neighbours = []
	for neighbour in adjacent:
		if $TileMap.get_cellv(neighbour) >= 0:
			neighbours.append(neighbour)

	return neighbours


func is_enclosed(start, visited):
	var enclosed = true
	for cardinal in get_cardinals(start):
		if $TileMap.get_cellv(cardinal) < 0:
			return false

		if not visited[cardinal.x][cardinal.y]:
			visited[cardinal.x][cardinal.y] = true
			enclosed = enclosed and is_enclosed(cardinal, visited)

	return enclosed


func flood_fill(start):
	if board_state[start.x][start.y] > 2:
		board_state[start.x][start.y] = turn + 3
	else:
		board_state[start.x][start.y] = turn

	fill_cell(start)

	for cardinal in get_cardinals(start):
		if (
			board_state[cardinal.x][cardinal.y] != turn
			or board_state[cardinal.x][cardinal.y] != turn + 3
		):
			if $TileMap.get_cellv(cardinal) >= 0:
				flood_fill(cardinal)


func detect_enclosed_spaces(cell):
	var neighbours = get_neighbours(cell)
	var visited_cells = []
	for x in range(board_width):
		visited_cells.append([])
		for y in range(board_height):
			var visited = false
			if board_state[x][y] == turn or board_state[x][y] == turn + 3:
				visited = true
			visited_cells[x].append(visited)

	for neighbour in neighbours:
		if not visited_cells[neighbour.x][neighbour.y]:
			if is_enclosed(neighbour, visited_cells):
				flood_fill(neighbour)


func _input(event):
	if event is InputEventMouseButton:
		var pos = event.position
		if event.pressed and move_step == 1:
			var cell = $TileMap.world_to_map($TileMap.to_local(pos))
			if $TileMap.get_cellv(cell) < 0 or board_state[cell.x][cell.y] > 0:
				return
			var cell_pos = $TileMap.map_to_world(cell) + $TileMap.global_position
			if $TileMap.get_cellv(cell) >= 0 and board_state[cell.x][cell.y] == 0:
				$Dice.global_position = cell_pos
				$Dice.global_position = $Dice.global_position + Vector2(16, 16)
			fill_cell(cell)
			detect_enclosed_spaces(cell)
			move_step = 2

		if not is_rolling and move_step == 0:
			print("click")
			dice_roll()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var cursor_position = get_global_mouse_position()
	var cell = $TileMap.world_to_map($TileMap.to_local(cursor_position))
	if $TileMap.get_cellv(cell) >= 0 and board_state[cell.x][cell.y] == 0:
		$Highlight.global_position = $TileMap.map_to_world(cell) + $TileMap.global_position

	if move_step == 1:
		$Dice.global_position = cursor_position + Vector2(0, -32)


func dice_roll():
	is_rolling = true
	$DiceRoller.show()
	$DiceRoller.roll()


func make_move(cell, dice):
	dice.global_position = $TileMap.map_to_world(cell)


func _on_RollTimer_timeout():
	is_rolling = false


func _on_DiceRoller_hide():
	print("Selected dice: ", $DiceRoller.result)
	if turn == 1:
		player_dice = $DiceRoller.result

	if turn == 2:
		opponent_dice = $DiceRoller.result

	move_step = 1
	remaining_paths = $DiceRoller.result
	$Dice.set_face($DiceRoller.result)
	$Dice.show()
