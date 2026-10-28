extends Control

@onready
var minigame_slot = $MinigameSlot
@onready
var timer_label = $CanvasLayer/HUD/TimeLeftLabel

var timer: float = 30.000
var game_over: bool = false

const MinigameScene: PackedScene = preload("res://scenes/test_minigame.tscn")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var minigame = MinigameScene.instantiate()
	minigame_slot.add_child(minigame)
	minigame.win.connect(timer_gain)
	minigame.lose.connect(timer_loss)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if game_over:
		return
	
	timer -= delta
	
	if timer <= 0:
		timer = maxf(timer, 0)
		game_over = true
		print("game over")
	
	
	
	timer_label.text = "%.3f" % timer
	
	
	


func timer_gain(score):
	if not game_over:
		timer += score
		print("gained score: " + str(score))

func timer_loss():
	if not game_over:
		print("womp womp")
		timer -= 3
