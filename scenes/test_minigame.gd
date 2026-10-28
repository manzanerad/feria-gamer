extends Control

signal win(score: float)
signal lose()

var score: float = 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	




func _on_win_pressed() -> void:
	win.emit(score)


func _on_lose_pressed() -> void:
	lose.emit()
