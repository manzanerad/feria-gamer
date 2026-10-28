extends Control

@onready
var minigame_slot = $MinigameSlot
@onready
var timer_label = $CanvasLayer/HUD/TimeLeftLabel

var timer: float = 30.000

const MinigameScene: PackedScene = preload("res://scenes/test_minigame.tscn")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var minigame = MinigameScene.instantiate()
	minigame_slot.add_child(minigame)
	minigame.win.connect(timer_gain)
	minigame.lose.connect(timer_loss)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if timer > 0:
		timer -= delta
		timer_label.text = "%.3f" % timer
	else:
		game_over()
	

func game_over() -> void:
	timer = 0
	timer_label.text = "%.3f" % timer
	print("game over")
	


func timer_gain(score):
	print("gained score: " + str(score))
	timer += (score/10) * 10

func timer_loss():
	print("womp womp")
	timer -= 3
