extends GutTest
## Cofre: cobra su coste y avisa de lo que sale; el objeto llega al jugador al acabar el revelado y
## el cofre desaparece; abierto no se vuelve a abrir; sin oro no se abre y lo avisa; cada cofre
## abierto encarece los demás.

const ChestScene := preload("res://entities/interactables/chest/chest.tscn")

var _chest: Chest
var _wallet: WalletComponent
var _items: PassiveInventory
var _opened: Array[PassiveItemData] = []
var _denied: Array[int] = []


func before_each() -> void:
	_opened.clear()
	_denied.clear()
	EventBus.chest_opened.connect(_on_opened)
	EventBus.chest_denied.connect(_on_denied)
	# Todas las fuentes del jugador: cualquier objeto que salga tiene sus stats.
	var stats := StatsComponent.new()
	var progression := ProgressionData.new()
	progression.currency_gain = 100.0
	stats.sources.append(progression)
	for source: Resource in [OffenseData.new(), HealthData.new(), MovementData.new(), StaminaData.new()]:
		stats.sources.append(source)
	add_child_autofree(stats)
	_wallet = WalletComponent.new()
	_wallet.stats = stats
	add_child_autofree(_wallet)
	_items = PassiveInventory.new()
	_items.stats = stats
	add_child_autofree(_items)
	_chest = _make_chest()


func after_each() -> void:
	EventBus.chest_opened.disconnect(_on_opened)
	EventBus.chest_denied.disconnect(_on_denied)


func test_pays_and_the_item_arrives_after_the_reveal() -> void:
	_wallet.add(100.0)
	var cost := _chest.get_cost()
	assert_true(_chest.open(_wallet, _items))
	assert_eq(_wallet.get_gold(), 100.0 - cost)
	assert_eq(_opened.size(), 1, "avisa de lo que sale")
	assert_not_null(_opened[0])
	assert_eq(_items.total(), 0, "aún revelándose")
	assert_false(_chest.interactable.enabled)
	assert_false(_chest.open(_wallet, _items), "abierto no se vuelve a abrir")
	await wait_seconds(_chest.data.reveal_time + 0.1)
	assert_eq(_items.get_items(), [_opened[0]] as Array[PassiveItemData], "le llega lo que salió")
	await wait_seconds(_chest.vanish_time + 0.1)
	assert_false(is_instance_valid(_chest), "y el cofre desaparece")


func test_without_gold_it_stays_closed() -> void:
	_wallet.add(1.0)
	assert_false(_chest.open(_wallet, _items))
	assert_eq(_wallet.get_gold(), 1.0)
	assert_false(_chest.is_open())
	assert_eq(_denied, [_chest.get_cost()] as Array[int])
	assert_eq(_opened.size(), 0)


func test_each_chest_opened_makes_the_others_pricier() -> void:
	var other := _make_chest()
	var before := other.get_cost()
	_wallet.add(1000.0)
	_chest.open(_wallet, _items)
	assert_gt(other.get_cost(), before)


func _make_chest() -> Chest:
	var chest := ChestScene.instantiate() as Chest
	chest.data = chest.data.duplicate() as ChestData
	chest.data.reveal_time = 0.2
	add_child_autofree(chest)
	return chest


func _on_opened(item: PassiveItemData, _reveal_time: float) -> void:
	_opened.append(item)


func _on_denied(cost: int) -> void:
	_denied.append(cost)
