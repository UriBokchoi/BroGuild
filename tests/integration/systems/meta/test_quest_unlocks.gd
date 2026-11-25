extends GutTest
## Misiones en el juego: lo bloqueado no sale al subir de nivel; al acabar una partida que cumple una
## misión, el RunRecorder la apunta en el perfil y los resultados lo dicen; en la selección de
## personaje, el que da una misión sin cumplir sale sin poder elegirse; la pestaña «Misiones» las
## lista con su estado.

const SWORD := preload("res://data/weapons/sword.tres")
const HAMMER := preload("res://data/weapons/hammer.tres")
const AXE := preload("res://data/weapons/axe.tres")
const WARRIOR := preload("res://data/characters/warrior.tres")
const MAGE := preload("res://data/characters/mage.tres")
const QUESTS := preload("res://data/meta/quests.tres")
const PlayerScene := preload("res://entities/player/player.tscn")
const LevelUpPanelScene := preload("res://ui/menus/level_up/level_up_panel.tscn")
const ResultsScene := preload("res://ui/menus/results/results_panel.tscn")
const SetupScene := preload("res://ui/menus/run_setup/run_setup.tscn")
const QuestsPanelScene := preload("res://ui/menus/quests/quests_panel.tscn")


func before_each() -> void:
	Save.profile = PlayerProfile.new()


func after_each() -> void:
	RunState.locked = []
	Save.profile = PlayerProfile.new()
	Save.save_profile()
	Save.load_leaderboard()
	get_tree().paused = false


func test_locked_weapons_never_show_up_when_leveling() -> void:
	RunState.locked = QUESTS.locked_content(Save.profile)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	var panel := LevelUpPanelScene.instantiate() as LevelUpPanel
	add_child_autofree(panel)
	var controller := LevelUpController.new()
	controller.data = preload("res://data/progression/level_up.tres")
	controller.player = player
	controller.panel = panel
	add_child_autofree(controller)
	var offerable := controller.get_offerable()
	assert_false(offerable.has(HAMMER), "el martillo, bloqueado")
	assert_false(offerable.has(AXE), "el hacha, bloqueada")
	assert_true(offerable.has(SWORD))
	player.weapons.add(AXE)
	assert_true(controller.get_offerable().has(AXE), "si ya la lleva, se puede subir")


func test_the_recorder_completes_quests_and_the_results_say_so() -> void:
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	player.set_character(WARRIOR)
	player.weapons.get_weapon(SWORD).set_level(10)
	var recorder := RunRecorder.new()
	recorder.player = player
	recorder.record_runs = true
	recorder.quests = QUESTS
	add_child_autofree(recorder)
	var results := ResultsScene.instantiate() as ResultsPanel
	results.recorder = recorder
	add_child_autofree(results)
	EventBus.run_won.emit(&"BROSQUE_VICTORY", 60.0, 1.0)
	assert_eq(recorder.completed_quests.size(), 1, "el martillo (el Guerrero no llegó a 30)")
	assert_true(Save.profile.has_completed(&"hammer"))
	assert_false(QUESTS.is_locked(HAMMER, Save.profile))
	results.open_victory(&"BROSQUE_VICTORY")
	assert_eq(results.get_rows().get("RESULTS_UNLOCKED", "") as String, tr(HAMMER.name_key))


func test_locked_characters_cannot_be_chosen() -> void:
	var catalog := QuestCatalog.new()
	var quest := QuestData.new()
	quest.id = &"mage_test"
	quest.description_key = &"QUEST_AXE_DESC"
	quest.reward = MAGE
	catalog.quests = [quest]
	var setup := SetupScene.instantiate() as RunSetup
	setup.quests = catalog
	add_child_autofree(setup)
	assert_true(setup.is_locked(MAGE))
	setup.choose(MAGE)
	assert_false(setup.is_choosing_level(), "no se puede elegir")
	Save.profile.complete_quest(&"mage_test")
	assert_false(setup.is_locked(MAGE))


func test_the_quests_panel_lists_them_with_their_state() -> void:
	Save.profile.complete_quest(QUESTS.quests[0].id)
	var panel := QuestsPanelScene.instantiate() as QuestsPanel
	add_child_autofree(panel)
	panel.open()
	var states := panel.get_states()
	assert_eq(states.size(), QUESTS.quests.size())
	assert_eq(states[0], tr(&"QUESTS_DONE"))
	assert_eq(states[1], tr(&"QUESTS_PENDING"))
