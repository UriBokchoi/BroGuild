extends GutTest
## Aviso de «interactuar» del HUD: aparece con la tecla y el texto que manda el EventBus y se oculta
## con un texto vacío.

const HudScene := preload("res://ui/hud/hud.tscn")

var _prompt: InteractionPrompt


func before_each() -> void:
	var hud := HudScene.instantiate()
	add_child_autofree(hud)
	_prompt = hud.get_node(^"%InteractionPrompt") as InteractionPrompt


func test_starts_hidden() -> void:
	assert_false(_prompt.visible)


func test_shows_the_key_and_the_text() -> void:
	EventBus.interaction_prompt_changed.emit(&"INTERACT_ARMORY")
	assert_true(_prompt.visible)
	assert_eq((_prompt.get_node(^"%PromptText") as Label).text, "INTERACT_ARMORY")
	assert_eq((_prompt.get_node(^"%PromptKey") as Label).text, InteractionPrompt.key_text(InputActions.INTERACT))
	assert_false(InteractionPrompt.key_text(InputActions.INTERACT).is_empty(), "«interactuar» tiene tecla")


func test_empty_text_hides_it() -> void:
	EventBus.interaction_prompt_changed.emit(&"INTERACT_ARMORY")
	EventBus.interaction_prompt_changed.emit(&"")
	assert_false(_prompt.visible)
