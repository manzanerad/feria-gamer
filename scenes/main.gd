extends Control
@onready
var minigame_slot = $MinigameSlot
const MinigameScene: PackedScene = preload("res://scenes/test_minigame.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var minigame = MinigameScene.instantiate()
	minigame_slot.add_child(minigame)
	minigame.win.connect(timer_gain)
	minigame.lose.connect(timer_loss)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func timer_gain(score):
	print("gained score: " + str(score))

func timer_loss():
	print("womp womp")
