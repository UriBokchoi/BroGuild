extends GutTest
## Aviso de que algo se puede usar (con un cofre de verdad): todas sus mallas llevan el destello de
## siempre, el más marcado si es el que se usaría ahora y ninguno al desactivarse.

const ChestScene := preload("res://entities/interactables/chest/chest.tscn")

var _chest: Chest
var _hint: InteractHint


func before_each() -> void:
	_chest = ChestScene.instantiate() as Chest
	add_child_autofree(_chest)
	_hint = _chest.get_node(^"InteractHint") as InteractHint


func test_glints_brighter_when_chosen_and_goes_off_when_disabled() -> void:
	assert_same(_hint.get_overlay(), _hint.idle_material)
	for mesh: Node in _chest.get_node(^"Visual").find_children("*", "MeshInstance3D", true, false):
		assert_same((mesh as MeshInstance3D).material_overlay, _hint.idle_material, "todas sus mallas")
	_chest.interactable.set_focused(true)
	assert_same(_hint.get_overlay(), _hint.focus_material)
	_chest.interactable.set_focused(false)
	assert_same(_hint.get_overlay(), _hint.idle_material)
	_chest.interactable.enabled = false
	assert_null(_hint.get_overlay(), "ya no se puede usar")
