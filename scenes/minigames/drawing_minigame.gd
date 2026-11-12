extends Node2D

signal win(score: float)
signal lose()

@export var max_time_reward: float = 10.0
@export var finish_radius: float = 12.0

const COVERAGE_SPACING: float = 4.0
const ACCURACY_SPACING: float = 2.0

@onready var outline: Line2D = $Outline

var mouse_is_clicked: bool = false
var current_stroke: Line2D
var drawing_started: bool = false
var drawing_start: Vector2
var has_left_start: bool = false
var finished: bool = false

var coverage_points: Array[Vector2] = []
var coverage_weights: Array[float] = []
var coverage_flags: Array[bool] = []
var outline_length: float = 0.0
var covered_length: float = 0.0
var total_drawn_length: float = 0.0
var weighted_accuracy: float = 0.0


func _ready() -> void:
	if outline.points.size() < 2 or outline.width <= 0.0:
		finished = true
		lose.emit()
		return
	prepare_coverage_samples(COVERAGE_SPACING)


func _process(_delta: float) -> void:
	if mouse_is_clicked and not finished:
		draw(outline.get_local_mouse_position())


func _input(event: InputEvent) -> void:
	if finished:
		return
	if event.is_action_pressed("click"):
		current_stroke = Line2D.new()
		current_stroke.width = 3.0
		current_stroke.default_color = Color.BLACK
		outline.add_child(current_stroke)
		mouse_is_clicked = true
		draw(outline.get_local_mouse_position())
	elif event.is_action_released("click"):
		if mouse_is_clicked:
			draw(outline.get_local_mouse_position())
		mouse_is_clicked = false


func draw(point: Vector2) -> void:
	if finished or current_stroke == null:
		return
	if not drawing_started:
		drawing_started = true
		drawing_start = point

	var count: int = current_stroke.get_point_count()
	if count == 0:
		current_stroke.add_point(point)
		if point.distance_to(drawing_start) > finish_radius:
			has_left_start = true
		return

	var previous: Vector2 = current_stroke.get_point_position(count - 1)
	if previous.is_equal_approx(point):
		return

	var closes_drawing: bool = false
	if has_left_start and previous.distance_to(drawing_start) > finish_radius:
		var intersection: float = Geometry2D.segment_intersects_circle(
			previous, point, drawing_start, finish_radius
		)
		if intersection >= 0.0:
			point = previous.lerp(point, intersection)
			closes_drawing = true

	current_stroke.add_point(point)
	record_segment(previous, point)
	if point.distance_to(drawing_start) > finish_radius:
		has_left_start = true
	if closes_drawing:
		finish_drawing()


func get_outline_distance(point: Vector2) -> float:
	var points: PackedVector2Array = outline.points
	var smallest_distance: float = INF
	var segment_count: int = points.size() if outline.closed else points.size() - 1

	for i in range(segment_count):
		var next_index: int = (i + 1) % points.size()
		var closest_point: Vector2 = Geometry2D.get_closest_point_to_segment(
			point, points[i], points[next_index]
		)
		smallest_distance = minf(smallest_distance, point.distance_to(closest_point))
	return smallest_distance


func get_point_accuracy(distance: float) -> float:
	var half_width: float = maxf(outline.width * 0.5, 0.001)
	return clampf(1.0 - distance / half_width, 0.0, 1.0)


func prepare_coverage_samples(spacing: float) -> void:
	coverage_points.clear()
	coverage_weights.clear()
	coverage_flags.clear()
	outline_length = 0.0
	covered_length = 0.0
	total_drawn_length = 0.0
	weighted_accuracy = 0.0
	spacing = maxf(spacing, 0.1)

	var points: PackedVector2Array = outline.points
	var segment_count: int = points.size() if outline.closed else points.size() - 1
	for i in range(segment_count):
		var next_index: int = (i + 1) % points.size()
		var segment_length: float = points[i].distance_to(points[next_index])
		if is_zero_approx(segment_length):
			continue
		var sample_count: int = maxi(1, ceili(segment_length / spacing))
		var sample_weight: float = segment_length / float(sample_count)
		for j in range(sample_count):
			var fraction: float = float(j) / float(sample_count)
			coverage_points.append(points[i].lerp(points[next_index], fraction))
			coverage_weights.append(sample_weight)
			coverage_flags.append(false)
		outline_length += segment_length


func record_segment(start: Vector2, end: Vector2) -> void:
	var segment_length: float = start.distance_to(end)
	if is_zero_approx(segment_length):
		return

	# Muestrea por distancia para que quedarse quieto no dé puntos.
	var sample_count: int = maxi(1, ceili(segment_length / ACCURACY_SPACING))
	var sample_weight: float = segment_length / float(sample_count)
	for i in range(sample_count):
		var fraction: float = (float(i) + 0.5) / float(sample_count)
		var sample_point: Vector2 = start.lerp(end, fraction)
		var accuracy: float = get_point_accuracy(get_outline_distance(sample_point))
		weighted_accuracy += accuracy * sample_weight
	total_drawn_length += segment_length

	var tolerance: float = outline.width * 0.5
	for i in range(coverage_points.size()):
		if coverage_flags[i]:
			continue
		var closest_point: Vector2 = Geometry2D.get_closest_point_to_segment(
			coverage_points[i], start, end
		)
		if coverage_points[i].distance_to(closest_point) <= tolerance:
			# Cada zona del contorno se cuenta una sola vez.
			coverage_flags[i] = true
			covered_length += coverage_weights[i]


func get_performance() -> Dictionary:
	var accuracy: float = 0.0
	var coverage: float = 0.0
	if total_drawn_length > 0.0:
		accuracy = clampf(weighted_accuracy / total_drawn_length, 0.0, 1.0)
	if outline_length > 0.0:
		coverage = clampf(covered_length / outline_length, 0.0, 1.0)
	return {
		"accuracy": accuracy,
		"coverage": coverage,
		"score": accuracy * coverage
	}


func finish_drawing() -> void:
	if finished:
		return
	finished = true
	mouse_is_clicked = false
	var performance: Dictionary = get_performance()
	print("Precisión: %.1f%% | Cobertura: %.1f%%" % [
		float(performance["accuracy"]) * 100.0,
		float(performance["coverage"]) * 100.0
	])
	win.emit(float(performance["score"]) * max_time_reward)
