extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func color(player) :
	match player:
		1:
			$AnimatedSprite.animation = "red"
			$AnimatedSprite.play()
		2:
			$AnimatedSprite.animation = "blue"
			$AnimatedSprite.play()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
