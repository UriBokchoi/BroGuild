extends GutTest
## QuestData y QuestCatalog: una partida cumple una misión si lleva su arma al nivel pedido, con su
## personaje, llega a su nivel y gana (si lo pide). Lo que da una misión sin cumplir está bloqueado;
## al cumplirla, se abre. El perfil guarda las cumplidas. Las de data/meta/quests.tres son las pedidas.

const SWORD := preload("res://data/weapons/sword.tres")
const HAMMER := preload("res://data/weapons/hammer.tres")
const AXE := preload("res://data/weapons/axe.tres")
const STAFF := preload("res://data/weapons/staff.tres")
const WARRIOR := preload("res://data/characters/warrior.tres")
const MAGE := preload("res://data/characters/mage.tres")
const QUESTS := preload("res://data/meta/quests.tres")


func _record(character: CharacterData, sword_level: int, player_level: int, won: bool) -> RunRecord:
	var record := RunRecord.new()
	record.character_id = character.id
	if sword_level > 0:
		record.weapons["sword"] = sword_level
	record.player_level = player_level
	record.won = won
	return record


func test_the_hammer_needs_the_sword_at_10_and_a_win() -> void:
	var quest := QUESTS.quest_for(HAMMER)
	assert_not_null(quest)
	assert_false(quest.is_met_by(_record(WARRIOR, 10, 20, false)), "sin ganar")
	assert_false(quest.is_met_by(_record(WARRIOR, 9, 20, true)), "espada a 9")
	assert_true(quest.is_met_by(_record(WARRIOR, 10, 20, true)))
	assert_true(quest.is_met_by(_record(MAGE, 12, 20, true)), "con cualquier personaje")


func test_the_axe_needs_the_warrior_at_30() -> void:
	var quest := QUESTS.quest_for(AXE)
	assert_not_null(quest)
	assert_false(quest.is_met_by(_record(WARRIOR, 0, 29, true)))
	assert_false(quest.is_met_by(_record(MAGE, 0, 35, true)), "con otro personaje")
	assert_true(quest.is_met_by(_record(WARRIOR, 0, 30, false)), "sin ganar también")


func test_the_starting_weapons_are_open() -> void:
	var profile := PlayerProfile.new()
	for weapon: WeaponData in [SWORD, STAFF, preload("res://data/weapons/dagger.tres")]:
		assert_false(QUESTS.is_locked(weapon, profile), "%s abierta" % weapon.id)
	assert_true(QUESTS.is_locked(HAMMER, profile))
	assert_true(QUESTS.is_locked(AXE, profile))
	assert_eq(QUESTS.locked_content(profile).size(), QUESTS.quests.size())


func test_completing_a_quest_unlocks_its_reward() -> void:
	var profile := PlayerProfile.new()
	var met := QUESTS.newly_met(_record(WARRIOR, 10, 30, true), profile)
	assert_eq(met.size(), 2, "martillo y hacha a la vez")
	for quest: QuestData in met:
		profile.complete_quest(quest.id)
	assert_false(QUESTS.is_locked(HAMMER, profile))
	assert_eq(QUESTS.newly_met(_record(WARRIOR, 10, 30, true), profile).size(), 0, "una sola vez")


func test_the_profile_keeps_the_completed_quests() -> void:
	var profile := PlayerProfile.new()
	assert_true(profile.complete_quest(&"hammer"))
	assert_false(profile.complete_quest(&"hammer"), "ya estaba")
	var config := ConfigFile.new()
	profile.write_to(config)
	var loaded := PlayerProfile.new()
	loaded.read_from(config)
	assert_true(loaded.has_completed(&"hammer"))
	assert_false(loaded.has_completed(&"axe"))


func test_the_profile_keeps_when_each_quest_was_completed() -> void:
	var profile := PlayerProfile.new()
	profile.complete_quest(&"hammer", 1700000000.0)
	profile.complete_quest(&"axe")
	assert_eq(profile.completed_at(&"hammer"), 1700000000.0)
	assert_gt(profile.completed_at(&"axe"), 1700000000.0, "sin fecha, ahora")
	assert_eq(profile.completed_at(&"warlock"), 0.0)
	var config := ConfigFile.new()
	profile.write_to(config)
	var loaded := PlayerProfile.new()
	loaded.read_from(config)
	assert_eq(loaded.completed_at(&"hammer"), 1700000000.0)


func test_the_keen_eye_rune_needs_2500_kills_in_one_run() -> void:
	var rune := preload("res://data/runes/keen_eye.tres")
	var quest := QUESTS.quest_for(rune)
	assert_not_null(quest)
	var record := _record(MAGE, 0, 10, false)
	record.kills = 2499
	assert_false(quest.is_met_by(record))
	record.kills = 2500
	assert_true(quest.is_met_by(record), "con cualquier personaje y sin ganar")
