# Declare member variables here. Examples:
# var a = 2
# var b = "text"
extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var score = [0, 0]
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
var is_starting = true
var is_finished = false
var active_dice
var move_step = 0
var last_dice_placement
var possible_rays = []
var visited_cells = []
var Castle = preload("res://Castle.tscn")
var FilledCell = preload("res://FilledCell.tscn")
var castles = []
var fillcount = 0
var win_threshold = 8
var winner = 0


func change_turn():
	$Player1.animation = "default"
	$Player2.animation = "default"
	if turn == 1:
		turn = 2
		$Player1.stop()
		$Player1.frame = 0
		$Player2.play()
		$Turn1.hide()
		$Turn2.show()
	elif turn == 2:
		turn = 1
		$Player2.stop()
		$Player2.frame = 0
		$Player1.play()
		$Turn2.hide()
		$Turn1.show()
		$RollIndicator.show()


func init_game():
	$Victory1/AnimationPlayer.play("RESET")
	$Victory2/AnimationPlayer.play("RESET")
	$Draw/AnimationPlayer.play("RESET")

	is_starting = true
	var clear_cells = false
	var clear_castles = false
	if cell_fills.size() > 0:
		clear_cells = true
	if castles.size() > 0:
		clear_castles = true

	board_state = []
	cell_fills = []
	visited_cells = []
	castles = []
	for x in range(board_width):
		board_state.append([])
		visited_cells.append([])
		if not clear_cells:
			cell_fills.append([])
		if not clear_castles:
			castles.append([])
		for y in range(board_height):
			board_state[x].append(0)
			visited_cells[x].append(false)
			if clear_cells:
				cell_fills[x][y].queue_free()
				cell_fills[x][y] = null
			else:
				cell_fills[x].append(null)

			if clear_castles:
				if castles[x][y] != null:
					castles[x][y].queue_free()
					castles[x][y] = null
			else:
				castles[x].append(null)

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

	win_threshold = floor(castle_coords.size() / 2) + 1

	for coord in castle_coords:
		var x = coord[0]
		var y = coord[1]
		board_state[x][y] = 3
		var castle = Castle.instance()
		add_child(castle)
		castle.global_position = $TileMap.map_to_world(Vector2(x, y)) + $TileMap.global_position
		castles[x][y] = castle

	move_step = 0
	is_rolling = false

	$TurnDecider.roll()
	$RollTimer.start()
	$StartSFX.play()


# Called when the node enters the scene tree for the first time.
func _ready():
	init_game()


func fill_cell(cell):
	if board_state[cell.x][cell.y] > 2:
		board_state[cell.x][cell.y] = turn + 3
	else:
		board_state[cell.x][cell.y] = turn
	if cell_fills[cell.x][cell.y] == null:
		cell_fills[cell.x][cell.y] = FilledCell.instance()
		cell_fills[cell.x][cell.y].global_position = ($TileMap.map_to_world(cell))
		add_child(cell_fills[cell.x][cell.y])
		fillcount += 1

	cell_fills[cell.x][cell.y].color(turn)

	if fillcount >= (board_height * board_width):
		winner = 0
		is_finished = true
		$Player1.animation = "defeat"
		$Player2.animation = "defeat"
		$Draw/AnimationPlayer.play("New Anim")
		$EndTimer.start()
		$VictorySFX.play()


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

	# print(neighbours)

	return neighbours


func is_enclosed(start):
	var enclosed = true
	visited_cells[start.x][start.y] = true
	for cardinal in get_cardinals(start):
		if $TileMap.get_cellv(cardinal) < 0:
			return false

		if not visited_cells[cardinal.x][cardinal.y]:
			enclosed = enclosed and is_enclosed(cardinal)

	return enclosed


func flood_fill(start):
	# print("Flooding ", start)

	# var t = Timer.new()
	# t.set_wait_time(1)
	# t.set_one_shot(true)
	# self.add_child(t)
	# t.start()
	# yield(t, "timeout")

	fill_cell(start)

	if castles[start.x][start.y] != null:
		score[turn - 1] += 1
		print(score)
		castles[start.x][start.y].capture(turn)
		$CaptureSFX.play()

	if score[turn - 1] >= win_threshold:
		winner = turn
		is_finished = true
		if winner == 1:
			$Player1.animation = "victory"
			$Player2.animation = "defeat"
			$Victory1/AnimationPlayer.play("New Anim")
		elif winner == 2:
			$Player1.animation = "defeat"
			$Player2.animation = "victory"
			$Victory2/AnimationPlayer.play("New Anim")

		$EndTimer.start()
		return

	for cardinal in get_cardinals(start):
		if $TileMap.get_cellv(cardinal) < 0:
			continue

		if (
			board_state[cardinal.x][cardinal.y] == turn
			or board_state[cardinal.x][cardinal.y] == turn + 3
		):
			continue

		flood_fill(cardinal)


func detect_enclosed_spaces(cell):
	var neighbours = get_neighbours(cell)

	for neighbour in neighbours:
		for x in range(board_width):
			for y in range(board_height):
				var visited = false
				if board_state[x][y] == turn or board_state[x][y] == turn + 3:
					visited = true
				visited_cells[x][y] = visited
		if not visited_cells[neighbour.x][neighbour.y]:
			if is_enclosed(neighbour):
				# print("Enclosure found at: ", neighbour)
				flood_fill(neighbour)


func _input(event):
	if event is InputEventMouseButton:
		var pos = event.position
		if event.pressed and move_step == 1 and turn == 1:
			var cell = $TileMap.world_to_map($TileMap.to_local(pos))
			make_move(cell)

		if not is_rolling and move_step == 0 and not is_starting and not is_finished and turn == 1:
			$RollIndicator.hide()
			dice_roll()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var cursor_position = get_global_mouse_position()
	var cell = $TileMap.world_to_map($TileMap.to_local(cursor_position))
	if $TileMap.get_cellv(cell) >= 0 and board_state[cell.x][cell.y] == 0:
		$Highlight.global_position = $TileMap.map_to_world(cell) + $TileMap.global_position

	if move_step == 1:
		$Dice.global_position = cursor_position + Vector2(0, -32)

	if turn == 2:
		if not is_rolling and not is_starting and not is_finished:
			if move_step == 0:
				dice_roll()

			if move_step == 1:
				var x = Global.rng.randi_range(0, board_width - 1)
				var y = Global.rng.randi_range(0, board_height - 1)

				# var i = 0
				# var x = ai_priority[i][0]
				# var y = ai_priority[i][1]
				# while board_state[x][y] != 0 and i < ai_priority.size() - 1:
				# 	i += 1
				# 	x = ai_priority[i][0]
				# 	y = ai_priority[i][0]
				
				# if i >= ai_priority.size():
				while board_state[x][y] != 0:
					x = Global.rng.randi_range(0, board_width - 1)
					y = Global.rng.randi_range(0, board_height - 1)

				print("AI move: ",x," ",y)
				
				make_move(Vector2(x, y))

			if move_step == 2:
				for _i in range(remaining_paths):
					var direction = Global.rng.randi_range(1, 8)
					while not $ArrowContainer.get_children()[direction - 1].is_visible_in_tree():
						direction = Global.rng.randi_range(1, 8)

					choose_direction(direction)


func dice_roll():
	is_rolling = true
	$DiceRoller.show()
	$DiceRoller.roll(turn == 2)


func make_move(cell):
	if $TileMap.get_cellv(cell) < 0 or board_state[cell.x][cell.y] > 0:
		return
	$Highlight.hide()
	var cell_pos = $TileMap.map_to_world(cell) + $TileMap.global_position
	last_dice_placement = cell
	$Dice.global_position = cell_pos + Vector2(16, 16)
	fill_cell(cell)
	detect_enclosed_spaces(cell)
	$ArrowContainer.global_position = cell_pos + Vector2(16, 16)
	$ArrowContainer.show()
	var directions = get_adjacent(cell)
	# print("Surrounding cells: ", directions)
	var valid_directions = 8
	for i in range(8):
		# print("Checking ", directions[i], board_state[directions[i].x][directions[i].y])
		if (
			$TileMap.get_cellv(directions[i]) < 0
			or board_state[directions[i].x][directions[i].y] > 2
		):
			# print(directions[i], " invalid")
			valid_directions -= 1
			$ArrowContainer.get_children()[i].hide()
	if valid_directions < remaining_paths:
		remaining_paths = valid_directions
	move_step = 2


func _on_RollTimer_timeout():
	if is_starting:
		var dice1 = $TurnDecider/DiceContainer1/CollisionShape2D/Dice1
		var dice2 = $TurnDecider/DiceContainer2/CollisionShape2D/Dice2

		if dice1.result > dice2.result:
			turn = 2
			change_turn()
		elif dice2.result > dice1.result:
			turn = 1
			change_turn()
		else:
			turn = Global.rng.randi_range(1, 2)
			change_turn()

		$TurnDecider.hide()

		is_starting = false


func _on_DiceRoller_hide():
	# print("Selected dice: ", $DiceRoller.result)
	if turn == 1:
		player_dice = $DiceRoller.result

	if turn == 2:
		opponent_dice = $DiceRoller.result

	move_step = 1
	remaining_paths = $DiceRoller.result
	$Dice.set_face($DiceRoller.result)
	$Dice.show()
	is_rolling = false


func choose_direction(direction):
	for i in range(1, 8 - $DiceRoller.result):
		# print(i)
		var cell
		match direction:
			1:
				cell = last_dice_placement + Vector2(0, -i)
			2:
				cell = last_dice_placement + Vector2(i, -i)
			3:
				cell = last_dice_placement + Vector2(i, 0)
			4:
				cell = last_dice_placement + Vector2(i, i)
			5:
				cell = last_dice_placement + Vector2(0, i)
			6:
				cell = last_dice_placement + Vector2(-i, i)
			7:
				cell = last_dice_placement + Vector2(-i, 0)
			8:
				cell = last_dice_placement + Vector2(-i, -i)

		if $TileMap.get_cellv(cell) < 0 or board_state[cell.x][cell.y] > 2:
			break

		# print(cell)
		fill_cell(cell)
		detect_enclosed_spaces(cell)

	$ArrowContainer.get_children()[direction - 1].hide()
	remaining_paths -= 1
	if remaining_paths < 1:
		for arrow in $ArrowContainer.get_children():
			arrow.show()
		$ArrowContainer.hide()

		$FillTimer.start()
		yield($FillTimer, "timeout")

		if not is_finished:
			change_turn()

		move_step = 0

	if is_finished:
		# display victory scene
		pass


func _on_Area2D_input_event(_viewport, event, _shape_idx):
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	choose_direction(1)


func _on_Area2D2_input_event(_viewport, event, _shape_idx):
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	choose_direction(2)


func _on_Area2D3_input_event(_viewport, event, _shape_idx):
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	choose_direction(3)


func _on_Area2D4_input_event(_viewport, event, _shape_idx):
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	choose_direction(4)


func _on_Area2D5_input_event(_viewport, event, _shape_idx):
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	choose_direction(5)


func _on_Area2D6_input_event(_viewport, event, _shape_idx):
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	choose_direction(6)


func _on_Area2D7_input_event(_viewport, event, _shape_idx):
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	choose_direction(7)


func _on_Area2D8_input_event(_viewport, event, _shape_idx):
	if not event is InputEventMouseButton:
		return
	if not event.pressed:
		return
	choose_direction(8)


func _on_EndTimer_timeout():
	if is_finished:
		get_tree().change_scene("res://MainMenu.tscn")


func _on_CaptureSFX_finished():
	if winner > 0:
		$VictorySFX.play()
		$BGM.stop()


func _on_StartSFX_finished():
	$BGM.play()


var ai_priority = [
	[4, 4],
	[5, 4],
	[6, 4],
	[7, 4],
	[8, 4],
	[9, 4],
	[10, 4],
	[10, 5],
	[10, 6],
	[10, 7],
	[10, 8],
	[10, 9],
	[10, 10],
	[9, 10],
	[8, 10],
	[7, 10],
	[6, 10],
	[5, 10],
	[4, 10],
	[4, 9],
	[4, 8],
	[4, 7],
	[4, 6],
	[4, 5],
	[3, 3],
	[4, 3],
	[5, 3],
	[6, 3],
	[7, 3],
	[8, 3],
	[9, 3],
	[10, 3],
	[11, 3],
	[11, 4],
	[11, 5],
	[11, 6],
	[11, 7],
	[11, 8],
	[11, 9],
	[11, 10],
	[11, 11],
	[10, 11],
	[9, 11],
	[8, 11],
	[7, 11],
	[6, 11],
	[5, 11],
	[4, 11],
	[3, 11],
	[3, 10],
	[3, 9],
	[3, 8],
	[3, 7],
	[3, 6],
	[3, 5],
	[3, 4],
	[2, 2],
	[3, 2],
	[4, 2],
	[5, 2],
	[6, 2],
	[7, 2],
	[8, 2],
	[9, 2],
	[10, 2],
	[11, 2],
	[12, 2],
	[12, 3],
	[12, 4],
	[12, 5],
	[12, 6],
	[12, 7],
	[12, 8],
	[12, 9],
	[12, 10],
	[12, 11],
	[12, 12],
	[11, 12],
	[10, 12],
	[9, 12],
	[8, 12],
	[7, 12],
	[6, 12],
	[5, 12],
	[4, 12],
	[3, 12],
	[2, 12],
	[2, 11],
	[2, 10],
	[2, 9],
	[2, 8],
	[2, 7],
	[2, 6],
	[2, 5],
	[2, 4],
	[2, 3],
	[5, 5],
	[6, 5],
	[7, 5],
	[8, 5],
	[9, 5],
	[9, 6],
	[9, 7],
	[9, 8],
	[9, 9],
	[8, 9],
	[7, 9],
	[6, 9],
	[5, 9],
	[5, 8],
	[5, 7],
	[5, 6],
	[1, 1],
	[2, 1],
	[3, 1],
	[4, 1],
	[5, 1],
	[6, 1],
	[7, 1],
	[8, 1],
	[9, 1],
	[10, 1],
	[11, 1],
	[12, 1],
	[13, 1],
	[13, 2],
	[13, 3],
	[13, 4],
	[13, 5],
	[13, 6],
	[13, 7],
	[13, 8],
	[13, 9],
	[13, 10],
	[13, 11],
	[13, 12],
	[13, 13],
	[12, 13],
	[11, 13],
	[10, 13],
	[9, 13],
	[8, 13],
	[7, 13],
	[6, 13],
	[5, 13],
	[4, 13],
	[3, 13],
	[2, 13],
	[1, 13],
	[1, 12],
	[1, 11],
	[1, 10],
	[1, 9],
	[1, 8],
	[1, 7],
	[1, 6],
	[1, 5],
	[1, 4],
	[1, 3],
	[1, 2],
	[6, 6],
	[7, 6],
	[8, 6],
	[8, 7],
	[8, 8],
	[7, 8],
	[6, 8],
	[6, 7],
	[0, 0],
	[1, 0],
	[2, 0],
	[3, 0],
	[4, 0],
	[5, 0],
	[6, 0],
	[7, 0],
	[8, 0],
	[9, 0],
	[10, 0],
	[11, 0],
	[12, 0],
	[13, 0],
	[14, 0],
	[14, 1],
	[14, 2],
	[14, 3],
	[14, 4],
	[14, 5],
	[14, 6],
	[14, 7],
	[14, 8],
	[14, 9],
	[14, 10],
	[14, 11],
	[14, 12],
	[14, 13],
	[14, 14],
	[13, 14],
	[12, 14],
	[11, 14],
	[10, 14],
	[9, 14],
	[8, 14],
	[7, 14],
	[6, 14],
	[5, 14],
	[4, 14],
	[3, 14],
	[2, 14],
	[1, 14],
	[0, 14],
	[0, 13],
	[0, 12],
	[0, 11],
	[0, 10],
	[0, 9],
	[0, 8],
	[0, 7],
	[0, 6],
	[0, 5],
	[0, 4],
	[0, 3],
	[0, 2],
	[0, 1],
	[7, 7]
]
