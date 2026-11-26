extends GutTest
## Cofre de la taberna: cerrado hasta derrotar a los enemigos que pide (dice cuántos van); luego se
## abre una vez y ofrece elegir entre 3 objetos, todos azules o mejores.

const KillChestScene := preload("res://entities/interactables/kill_chest/kill_chest.tscn")
const TavernScene := preload("res://entities/interactables/heal_shop/tavern.tscn")

var _chest: KillChest
var _offered: Array[PassiveItemData] = []


func before_each() -> void:
	_offered = []
	EventBus.item_choice_offered.connect(_on_offered)
	_chest = KillChestScene.instantiate() as KillChest
	_chest.kills_needed = 3
	_chest.rng = RandomNumberGenerator.new()
	add_child_autofree(_chest)


func after_each() -> void:
	EventBus.item_choice_offered.disconnect(_on_offered)


func _on_offered(items: Array[PassiveItemData]) -> void:
	_offered = items


func test_it_stays_closed_until_enough_kills() -> void:
	EventBus.enemy_died.emit(null)
	EventBus.enemy_died.emit(null)
	assert_false(_chest.is_ready())
	assert_false(_chest.open(), "aún no")
	assert_eq(_chest.progress_label.text, "2 / 3", "dice cuántos van")
	EventBus.enemy_died.emit(null)
	assert_true(_chest.is_ready())


func test_it_offers_three_blue_or_better_items_once() -> void:
	for _kill: int in 3:
		EventBus.enemy_died.emit(null)
	assert_true(_chest.open())
	assert_eq(_offered.size(), 3)
	var allowed := _chest.items.rarities.entries
	for item: PassiveItemData in _offered:
		assert_true(allowed.has(item.rarity), "%s: azul o mejor" % item.id)
	assert_false(_chest.open(), "una sola vez")


func test_the_tavern_has_one() -> void:
	var tavern := TavernScene.instantiate()
	add_child_autofree(tavern)
	var chest := tavern.find_child("KillChest", true, false) as KillChest
	assert_not_null(chest)
	assert_eq(chest.kills_needed, 1500)
