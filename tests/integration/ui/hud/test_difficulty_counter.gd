extends GutTest
## Dificultad en el HUD: muestra la del jugador con un decimal y se pone al día cuando cambia su stat.

const HudScene := preload("res://ui/hud/hud.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")

var _hud: Node


func before_each() -> void:
	RunState.character = null
	_hud = HudScene.instantiate()
	add_child_autofree(_hud)


func after_each() -> void:
	RunState.character = null


func test_follows_the_player_difficulty() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	var label := _hud.get_node(^"%DifficultyLabel") as Label
	assert_eq(label.text, "0.0")
	player.stats.add_modifier(StatModifier.create(&"difficulty", StatModifier.Kind.FLAT, 2.5), self)
	assert_eq(label.text, "2.5")
