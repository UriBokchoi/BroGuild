extends GutTest
## El Ent-renador (jefe del Brosque, raíz Boss): sale de un enjambre, es jefe y recalcula su rumbo en
## cada tick. El Burpee marca dónde va a caer (a lo sumo a su distancia máxima) y salta hacia ahí;
## las Series apuntan con su franja, embisten en línea recta con más daño y repiten; los Bro-tes
## piden refuerzos tras llamarlos (más con rabia). Por debajo de la mitad de su vida entra en rabia
## una sola vez (más rápido, grita) sin rellenarse la vida; al volver a salir es el de siempre.

const ENT_TRAINER := preload("res://data/enemies/ent_trainer.tres")
const SAPLING := preload("res://data/enemies/sapling.tres")

var _boss: Boss
var _shouts: Array[StringName] = []
var _calls: Array = []


func before_each() -> void:
	_shouts.clear()
	_calls.clear()
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	_boss = swarm.spawn(ENT_TRAINER, Vector3.ZERO) as Boss
	_boss.shouted.connect(_on_shout)
	_boss.summon_requested.connect(_on_summon)
	# La física calcula su gravedad en el primer tick (la usa el salto).
	await wait_physics_frames(2)


func test_is_a_boss_with_its_three_attacks() -> void:
	assert_not_null(_boss, "su escena tiene raíz Boss")
	assert_true(_boss.is_boss())
	assert_true(_boss.steer_every_tick)
	assert_true(_boss.get_node(^"Burpee") is LeapAttack)
	assert_true(_boss.get_node(^"Series") is ChargeAttack)
	assert_true(_boss.get_node(^"BroTes") is SummonAttack)


func test_the_burpee_marks_where_it_lands_and_jumps_there() -> void:
	var burpee := _boss.get_node(^"Burpee") as LeapAttack
	var far := _boss.global_position + Vector3(100.0, 0.0, 0.0)
	burpee.begin(far)
	assert_true(burpee.landing_marker.visible)
	var reach := burpee.landing_marker.global_position.x - _boss.global_position.x
	assert_almost_eq(reach, burpee.max_distance, 0.01, "a lo sumo a su distancia máxima")
	assert_false(burpee.step(burpee.windup + 0.01, far))
	assert_gt(_boss.linear_velocity.y, 0.0, "salta")
	assert_gt(_boss.linear_velocity.x, 0.0, "hacia donde marcó")
	burpee.cancel()
	assert_false(burpee.landing_marker.visible)


func test_the_sets_aim_charge_harder_and_repeat() -> void:
	var series := _boss.get_node(^"Series") as ChargeAttack
	var target := _boss.global_position + Vector3(0.0, 0.0, -30.0)
	var contact := _boss.contact_hitbox.base_damage
	series.begin(target)
	assert_true(series.lane.visible, "la franja marca por dónde irá")
	series.step(series.windup + 0.01, target)
	assert_false(series.lane.visible)
	assert_almost_eq(_boss.contact_hitbox.base_damage, contact * series.damage_factor, 0.01)
	series.step(0.01, target)
	assert_almost_eq(_boss.linear_velocity.z, -series.speed, 0.01, "en línea recta hacia el objetivo")
	var finished := false
	for _tick: int in 200:
		finished = series.step(0.05, target)
		if finished:
			break
	assert_true(finished, "termina tras sus repeticiones")
	assert_almost_eq(_boss.contact_hitbox.base_damage, contact, 0.01, "vuelve a su daño normal")


func test_the_sprouts_call_reinforcements_more_when_enraged() -> void:
	var sprouts := _boss.get_node(^"BroTes") as SummonAttack
	sprouts.begin(Vector3.ZERO)
	sprouts.step(sprouts.windup * 0.5, Vector3.ZERO)
	assert_eq(_calls.size(), 0, "aún llamándolos")
	sprouts.step(sprouts.windup, Vector3.ZERO)
	assert_eq(_calls, [[SAPLING, sprouts.count]])
	_enrage()
	sprouts.begin(Vector3.ZERO)
	sprouts.step(sprouts.windup + 0.01, Vector3.ZERO)
	var last: Array = _calls.back()
	assert_eq(last, [SAPLING, sprouts.enraged_count])


func test_enrages_once_below_half_health() -> void:
	var speed := _boss.stats.get_value(&"move_speed")
	var maximum := _boss.health.get_maximum()
	_boss.health.take_damage(DamageInfo.create(maximum * 0.4))
	assert_false(_boss.is_enraged())
	_boss.health.take_damage(DamageInfo.create(maximum * 0.2))
	assert_true(_boss.is_enraged())
	assert_gt(_boss.stats.get_value(&"move_speed"), speed, "más rápido")
	assert_almost_eq(_boss.health.get_current(), maximum * 0.4, 1.0, "la rabia no le rellena la vida")
	assert_eq(_shouts, _boss.enrage_shouts)
	_boss.health.take_damage(DamageInfo.create(maximum * 0.1))
	assert_eq(_shouts.size(), 1, "una sola vez")


func test_spawning_again_clears_the_rage() -> void:
	var speed := _boss.stats.get_value(&"move_speed")
	_enrage()
	_boss.spawn(Vector3.ZERO)
	assert_false(_boss.is_enraged())
	assert_almost_eq(_boss.stats.get_value(&"move_speed"), speed, 0.001)
	assert_eq(_boss.health.get_current(), _boss.health.get_maximum())


func _enrage() -> void:
	_boss.health.take_damage(DamageInfo.create(_boss.health.get_maximum() * 0.6))


func _on_shout(text_key: StringName) -> void:
	_shouts.append(text_key)


func _on_summon(enemy: EnemyData, count: int, _center: Vector3, _min_distance: float, _max_distance: float) -> void:
	_calls.append([enemy, count])
