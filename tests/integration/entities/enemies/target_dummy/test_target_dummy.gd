extends GutTest
## Muñeco de práctica: cuenta como enemigo (capas de enemigo), no muere ni pierde vida, avisa de cada
## golpe por el EventBus desde encima de su cabeza y se bambolea al recibirlo.

const DummyScene := preload("res://entities/enemies/target_dummy/target_dummy.tscn")

var _dummy: StaticBody3D
var _health: HealthComponent


func before_each() -> void:
	_dummy = DummyScene.instantiate() as StaticBody3D
	add_child_autofree(_dummy)
	_health = _dummy.get_node(^"Health") as HealthComponent


func test_counts_as_an_enemy() -> void:
	assert_eq(_dummy.collision_layer, PhysicsLayers.mask(PhysicsLayers.ENEMY))
	var hurtbox := _dummy.get_node(^"Hurtbox") as HurtboxComponent
	assert_eq(hurtbox.collision_layer, PhysicsLayers.mask(PhysicsLayers.ENEMY_HURTBOX))


func test_never_dies_nor_loses_health() -> void:
	watch_signals(_health)
	_health.take_damage(DamageInfo.create(100000.0))
	assert_eq(_health.get_current(), _health.get_maximum())
	assert_false(_health.is_dead())
	var amount: float = get_signal_parameters(_health, "damaged")[0]
	assert_eq(amount, 100000.0, "cuenta el golpe entero")


func test_reports_each_hit_above_its_head() -> void:
	watch_signals(EventBus)
	_health.take_damage(DamageInfo.create(25.0))
	var parameters: Array = get_signal_parameters(EventBus, "enemy_damaged")
	var at: Vector3 = parameters[0]
	var amount: float = parameters[1]
	assert_eq(amount, 25.0)
	assert_gt(at.y, 2.0, "encima de la cabeza")


func test_wobbles_when_hit_and_settles() -> void:
	var wobble := _dummy.get_node(^"HitWobble") as HitWobble
	_health.take_damage(DamageInfo.create(10.0))
	for _frame: int in 6:
		wobble._process(1.0 / 60.0)
	assert_gt(wobble.get_tilt_degrees(), 1.0, "se inclina")
	for _frame: int in 240:
		wobble._process(1.0 / 60.0)
	assert_lt(wobble.get_tilt_degrees(), 0.5, "vuelve a su sitio")
