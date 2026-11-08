extends GutTest
## StaminaPool: gastar cargas (también medias), recargar y cambiar el máximo.

var _pool: StaminaPool


func before_each() -> void:
	_pool = StaminaPool.new()
	_pool.max_charges = 3
	_pool.fill()


func test_spends_while_there_are_charges() -> void:
	assert_true(_pool.spend(1.0))
	assert_true(_pool.spend(1.0))
	assert_true(_pool.spend(1.0))
	assert_false(_pool.spend(1.0), "sin cargas no se gasta")
	assert_eq(_pool.charges, 0.0)


func test_half_charges() -> void:
	assert_true(_pool.spend(0.5))
	assert_eq(_pool.charges, 2.5)
	_pool.charges = 0.5
	assert_true(_pool.can_spend(0.5))
	assert_false(_pool.can_spend(1.0))


func test_recharges_one_charge_per_recharge_time() -> void:
	_pool.charges = 1.0
	for _tick: int in 180:
		_pool.recharge(1.0 / 60.0, 3.0)
	assert_almost_eq(_pool.charges, 2.0, 1e-9, "3 s = 1 carga")
	assert_true(_pool.can_spend(2.0), "la carga recargada se puede gastar entera")


func test_recharge_stops_at_the_max() -> void:
	_pool.charges = 2.9
	assert_true(_pool.recharge(1.0, 3.0))
	assert_eq(_pool.charges, 3.0)
	assert_false(_pool.recharge(1.0, 3.0), "llena no cambia")


func test_lowering_the_max_clamps_the_charges() -> void:
	_pool.max_charges = 2
	assert_eq(_pool.charges, 2.0)
