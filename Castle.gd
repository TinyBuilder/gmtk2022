extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var state = 0
onready var sprite = $AnimatedSprite

func capture(player_ID):
	state = player_ID
	sprite.frame = state

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
