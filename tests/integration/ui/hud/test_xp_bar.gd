extends GutTest
## Barra de experiencia del HUD: muestra la experiencia hacia el siguiente nivel y el nivel.

const HudScene := preload("res://ui/hud/hud.tscn")

var _hud: Node


func before_each() -> void:
	_hud = HudScene.instantiate()
	add_child_autofree(_hud)


func test_shows_progress_and_level() -> void:
	EventBus.player_xp_changed.emit(3.0, 12.0, 4)
	var bar := _hud.get_node(^"%XpProgress") as ProgressBar
	assert_eq(bar.max_value, 12.0)
	assert_eq(bar.value, 3.0)
	assert_string_contains((_hud.get_node(^"%LevelLabel") as Label).text, "4")
