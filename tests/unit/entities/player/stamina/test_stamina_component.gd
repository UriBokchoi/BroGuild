extends GutTest
## StaminaComponent: empieza llena, gasta, recarga según sus stats y avisa por EventBus.

const TICK := 1.0 / 60.0

var _stats: StatsComponent
var _stamina: StaminaComponent
var _data: StaminaData


func before_each() -> void:
	_data = StaminaData.new()
	_data.max_charges = 3
	_data.recharge_time = 2.0
	_stats = StatsComponent.new()
	_stats.sources.append(_data)
	add_child_autofree(_stats)
	_stamina = StaminaComponent.new()
	_stamina.stats = _stats
	add_child_autofree(_stamina)


func test_starts_full() -> void:
	assert_eq(_stamina.get_charges(), 3.0)
	assert_eq(_stamina.get_max_charges(), 3)


func test_spending_notifies_the_interface() -> void:
	watch_signals(EventBus)
	assert_true(_stamina.spend(1.0))
	assert_signal_emitted_with_parameters(EventBus, "player_stamina_changed", [2.0, 3])


func test_recharges_with_its_stat() -> void:
	_stamina.spend(1.0)
	for _tick: int in 60:
		_stamina._physics_process(TICK)
	assert_almost_eq(_stamina.get_charges(), 2.5, 1e-6, "1 s de 2 s por carga = media carga")


func test_an_upgrade_adds_a_charge() -> void:
	_stats.add_modifier(StatModifier.create(&"max_charges", StatModifier.Kind.FLAT, 1.0), self)
	_stamina._physics_process(TICK)
	assert_eq(_stamina.get_max_charges(), 4)
