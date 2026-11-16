extends GutTest
## Contador de oro del HUD: muestra el oro del jugador sin decimales.

const HudScene := preload("res://ui/hud/hud.tscn")

var _hud: Node


func before_each() -> void:
	_hud = HudScene.instantiate()
	add_child_autofree(_hud)


func test_shows_whole_gold() -> void:
	EventBus.player_gold_changed.emit(12.7)
	assert_eq((_hud.get_node(^"%GoldLabel") as Label).text, "12")
