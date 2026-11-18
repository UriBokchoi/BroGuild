extends GutTest
## Taberna: cobra su coste y cura la mitad de la vida máxima; cada vez cuesta más (y más con la
## dificultad); sin oro no cura y con la vida llena no cobra, y lo dice en el HUD.

const TavernScene := preload("res://entities/interactables/heal_shop/tavern.tscn")

var _shop: HealShop
var _wallet: WalletComponent
var _health: HealthComponent
var _announced: Array[StringName] = []


func before_each() -> void:
	_announced.clear()
	EventBus.announced.connect(_on_announced)
	var stats := StatsComponent.new()
	var data := HealthData.new()
	data.max_health = 100.0
	stats.sources.append(data)
	var progression := ProgressionData.new()
	progression.currency_gain = 100.0
	stats.sources.append(progression)
	add_child_autofree(stats)
	_health = HealthComponent.new()
	_health.stats = stats
	_health.rules = CombatRules.new()
	_health.rules.armor_for_half_damage = 100.0
	add_child_autofree(_health)
	_wallet = WalletComponent.new()
	_wallet.stats = stats
	add_child_autofree(_wallet)
	_shop = TavernScene.instantiate() as HealShop
	add_child_autofree(_shop)


func after_each() -> void:
	EventBus.announced.disconnect(_on_announced)


func test_pays_and_heals_half_and_gets_pricier() -> void:
	_wallet.add(500.0)
	_health.take_damage(DamageInfo.create(80.0))
	var cost := _shop.get_cost()
	assert_true(_shop.serve(_wallet, _health))
	assert_eq(_health.get_current(), 70.0, "la mitad de 100")
	assert_eq(_wallet.get_gold(), 500.0 - cost)
	assert_gt(_shop.get_cost(), cost, "la siguiente, más cara")
	assert_eq(_announced, [_shop.healed_key] as Array[StringName])


func test_without_gold_or_with_full_health_nothing_happens() -> void:
	assert_false(_shop.serve(_wallet, _health), "con la vida llena")
	var last: StringName = _announced.back()
	assert_eq(last, _shop.full_key)
	_health.take_damage(DamageInfo.create(50.0))
	assert_false(_shop.serve(_wallet, _health), "sin oro")
	last = _announced.back()
	assert_eq(last, _shop.denied_key)
	assert_eq(_health.get_current(), 50.0)
	assert_eq(_shop.get_uses(), 0)


func test_difficulty_raises_the_cost() -> void:
	var cost := _shop.get_cost()
	EventBus.difficulty_changed.emit(5.0)
	assert_gt(_shop.get_cost(), cost)


func _on_announced(text_key: StringName, _args: Array, _color: Color) -> void:
	_announced.append(text_key)
