extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button1_input_event(viewport:Node, event:InputEvent, shape_idx:int):
	if event is InputEventMouseButton:
		if event.pressed:
			get_tree().change_scene("res://AI.tscn")

func _on_Button2_input_event(viewport:Node, event:InputEvent, shape_idx:int):
	if event is InputEventMouseButton:
		if event.pressed:
			get_tree().change_scene("res://Field.tscn")

func _on_Button3_input_event(viewport:Node, event:InputEvent, shape_idx:int):
	if event is InputEventMouseButton:
		if event.pressed:
			$Rules.show()
			$"Menu option".hide()
			$SFX.play()

func _on_Button4_input_event(viewport:Node, event:InputEvent, shape_idx:int):
	if event is InputEventMouseButton:
		if event.pressed:
			$Credits.show()
			$"Menu option".hide()
			$SFX.play()

func _on_Credits_back_to_main():
	$Credits.hide()
	$"Menu option".show()
	$SFX.play()

func _on_Rules_close_rules():
	$Rules.hide()
	$"Menu option".show()
	$SFX.play()