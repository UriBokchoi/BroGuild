extends GutTest
## Reloj de la ronda del HUD: minutos:segundos, en rojo pasada la ronda y oculto sin ronda.

const HudScene := preload("res://ui/hud/hud.tscn")

var _clock: Label


func before_each() -> void:
	var hud := HudScene.instantiate()
	add_child_autofree(hud)
	_clock = hud.get_node(^"%RunClock") as Label


func test_hidden_until_a_round_runs() -> void:
	assert_false(_clock.visible)


func test_shows_minutes_and_seconds() -> void:
	EventBus.run_clock_changed.emit(65.7, false)
	assert_true(_clock.visible)
	assert_eq(_clock.text, "1:05")
	assert_eq(_clock.theme_type_variation, &"ClockLabel")


func test_turns_red_after_the_round() -> void:
	EventBus.run_clock_changed.emit(601.0, true)
	assert_eq(_clock.text, "10:01")
	assert_eq(_clock.theme_type_variation, &"ClockLabelOvertime")


func test_hides_when_the_round_stops() -> void:
	EventBus.run_clock_changed.emit(30.0, false)
	EventBus.run_clock_changed.emit(-1.0, false)
	assert_false(_clock.visible)
