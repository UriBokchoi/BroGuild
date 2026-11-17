extends GutTest
## WalletComponent: suma el oro recogido por su oro ganado (currency_gain), solo de su recompensa,
## y gasta solo si le llega.

var _wallet: WalletComponent


func before_each() -> void:
	var progression := ProgressionData.new()
	progression.currency_gain = 150.0
	var stats := StatsComponent.new()
	stats.sources.append(progression)
	add_child_autofree(stats)
	_wallet = WalletComponent.new()
	_wallet.stats = stats
	add_child_autofree(_wallet)


func test_adds_gold_with_its_gain() -> void:
	watch_signals(_wallet)
	_wallet.add(10.0)
	assert_eq(_wallet.get_gold(), 15.0)
	assert_signal_emitted_with_parameters(_wallet, "gold_changed", [15.0])


func test_collects_only_its_reward() -> void:
	EventBus.pickup_collected.emit(&"gold", 2.0)
	EventBus.pickup_collected.emit(&"experience", 50.0)
	assert_eq(_wallet.get_gold(), 3.0, "la experiencia no es oro")


func test_spends_only_what_it_has() -> void:
	_wallet.add(10.0)
	assert_false(_wallet.spend(20.0))
	assert_eq(_wallet.get_gold(), 15.0, "sin cambios")
	assert_true(_wallet.spend(5.0))
	assert_eq(_wallet.get_gold(), 10.0)
