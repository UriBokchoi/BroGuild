extends GutTest
## Bienvenida del HUD: muestra los mensajes del nivel (el primero, grande) y se oculta sola.

const HudScene := preload("res://ui/hud/hud.tscn")

var _intro: LevelIntro


func before_each() -> void:
	var hud := HudScene.instantiate()
	add_child_autofree(hud)
	_intro = hud.get_node(^"%LevelIntro") as LevelIntro
	_intro.display_time = 0.1
	_intro.fade_time = 0.1


func test_hidden_until_a_level_starts() -> void:
	assert_false(_intro.visible)


func test_shows_the_messages_and_then_goes_away() -> void:
	EventBus.level_intro.emit([&"BROSQUE_INTRO_WELCOME", &"BROSQUE_INTRO_NO_PAIN"] as Array[StringName])
	assert_true(_intro.visible)
	assert_eq(_intro.get_lines(), ["BROSQUE_INTRO_WELCOME", "BROSQUE_INTRO_NO_PAIN"] as Array[String])
	assert_eq((_intro.get_child(0) as Label).theme_type_variation, &"IntroTitleLabel")
	await wait_seconds(0.4)
	assert_false(_intro.visible)
