extends Control

@onready
var minigame_slot = $MinigameSlot
@onready
var timer_label = $CanvasLayer/HUD/TimeLeftLabel

var timer: float = 30.000
var game_over: bool = false
var total_score: float = 0
var minigames_passed: int = 0
var minigames_won: int = 0
var results_screen_timer: float = 3

const MinigameAScene: PackedScene = preload("res://scenes/test_minigame_a.tscn")
const MinigameBScene: PackedScene = preload("res://scenes/test_minigame_b.tscn")

var minigames: Array[PackedScene] = [MinigameAScene, MinigameBScene]



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_minigame()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if game_over:
		return
	
	timer_label.text = "%.3f" % timer
	
	if not $ResultsScreen.visible:
		timer -= delta
	
	if timer <= 0:
		
		timer = maxf(timer, 0)
		timer_label.text = "%.3f" % timer
		game_over = true
		print("game over")


func timer_gain(score):
	if not game_over:
		minigames_won += 1
		timer += score
		print("gained score: " + str(score))
		$MinigameSlot.get_child(0).queue_free()
		results_screen(score)
		
		


func timer_loss():
	if not game_over:
		print("womp womp")
		timer -= 3
		$MinigameSlot.get_child(0).queue_free()
		results_screen(0)


func load_minigame():
	$ResultsScreen.hide()
	var minigame = minigames.pick_random().instantiate()
	minigame.win.connect(timer_gain)
	minigame.lose.connect(timer_loss)
	minigame_slot.add_child(minigame)
	minigames_passed += 1


func results_screen(score):
		$ResultsScreen.show()
		total_score += score
		results_screen_timer = snappedf(results_screen_timer*0.9, 0.01)
		if results_screen_timer <= 1.0:
			results_screen_timer = maxf(results_screen_timer, 1.0)
		print("results timer: " + str(results_screen_timer))
		$ResultsScreen/ResultsLabel.set_text(
			"Score: "
			+ str(total_score)
			+ "\n"
			+ "total minigames: "
			+ str(minigames_passed)
			+ "\n"
			+ "minigames won: "
			+ str(minigames_won)
		)
		await get_tree().create_timer(results_screen_timer).timeout
		load_minigame()
		
		
