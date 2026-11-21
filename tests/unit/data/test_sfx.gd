extends GutTest
## Sonidos: cada receta de data/audio/sfx tiene su .wav generado, cada sonido del banco tiene audio,
## todo recogible suena y la racha es de un recogible que existe.

const BANK := preload("res://data/audio/sfx_bank.tres")
const RECIPES_DIR := "res://data/audio/sfx"
const SOUNDS_DIR := "res://assets/audio/sfx"
const PICKUPS_DIR := "res://data/pickups"


func test_every_recipe_was_generated() -> void:
	var recipes := ResourceDir.load_all(RECIPES_DIR, SfxRecipe)
	assert_gt(recipes.size(), 0)
	for recipe: Resource in recipes:
		var recipe_name := recipe.resource_path.get_file().get_basename()
		assert_true(ResourceLoader.exists("%s/%s.wav" % [SOUNDS_DIR, recipe_name]), "%s: falta su .wav (tools/gen_sfx.gd)" % recipe_name)


func test_every_cue_has_sound() -> void:
	for property: Dictionary in BANK.get_property_list():
		var property_name: StringName = property["name"]
		var value: Variant = BANK.get(property_name)
		if value is SoundCue:
			assert_not_null((value as SoundCue).stream, "%s: sin audio" % property_name)
	for reward: StringName in BANK.pickups:
		assert_not_null(BANK.pickups[reward].stream, "recogible %s: sin audio" % reward)


func test_every_pickup_has_a_sound() -> void:
	for pickup: Resource in ResourceDir.load_all(PICKUPS_DIR, PickupData):
		var reward: StringName = (pickup as PickupData).reward
		assert_true(BANK.pickups.has(reward), "%s: no suena al recogerlo" % reward)
	assert_true(BANK.pickups.has(BANK.streak_reward), "la racha es de un recogible que suena")


func test_the_mix_is_turned_down_by_default() -> void:
	assert_lt(BANK.volume_db, 0.0, "los efectos de serie, por debajo del máximo")
