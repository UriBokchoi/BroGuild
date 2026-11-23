extends GutTest
## El Trolleador Cara (miniboss del Brosque, raíz Boss) con física real: es jefe, trepa y tiene sus dos
## ataques. El Porrazo marca en el suelo hasta dónde llega, levanta la porra mientras el aviso se
## abre y, al caer, daña una vez a lo que está dentro (su contacto × su factor), no a lo de fuera; al
## cortarlo, quita los avisos y baja la porra. Su modelo es el mismo que el de los trolls de piedra.

const TROLLEADOR := preload("res://data/enemies/trolleador.tres")
const RULES := preload("res://data/combat/rules.tres")

var _boss: Boss


func before_each() -> void:
	_add_ground()
	var swarm := EnemySwarm.new()
	add_child_autofree(swarm)
	_boss = swarm.spawn(TROLLEADOR, Vector3.ZERO) as Boss
	# Sin ataques propios: los tests los empiezan a mano.
	_boss.set(&"_until_attack", 1000.0)
	await wait_physics_frames(2)


func test_is_a_boss_that_climbs_with_its_two_attacks() -> void:
	assert_not_null(_boss, "su escena tiene raíz Boss")
	assert_true(_boss.is_boss())
	assert_true(_boss.get_node(^"Porrazo") is SlamAttack)
	assert_true(_boss.get_node(^"Salto") is LeapAttack)
	var stats := _boss.stats.get_resolved(EnemyStats) as EnemyStats
	assert_gt(stats.climb_speed, 0.0, "trepa por las pesas")
	assert_gt(_boss.wall_probe_reach, 1.15, "su sonda sale de su cuerpo")


func test_the_slam_warns_raises_the_club_and_hits_inside_only() -> void:
	var slam := _boss.get_node(^"Porrazo") as SlamAttack
	var inside := _target(Vector3(4.0, 0.0, 0.0))
	var outside := _target(Vector3(slam.shockwave.radius + 4.0, 0.0, 0.0))
	await wait_physics_frames(2)
	var rest := slam.arm.rotation.x
	slam.begin(Vector3(4.0, 0.0, 0.0))
	assert_true(slam.edge_marker.visible, "marca hasta dónde llega")
	assert_true(slam.charge_marker.visible)
	assert_almost_eq(slam.edge_marker.scale.x, slam.shockwave.radius, 0.001)
	assert_false(slam.step(slam.windup, Vector3.ZERO))
	assert_almost_eq(slam.arm.rotation.x, slam.raised_angle, 0.01, "porra arriba")
	assert_eq(inside.get_current(), 100.0, "aún no ha caído")
	assert_false(slam.step(slam.swing_time + 0.001, Vector3.ZERO))
	assert_eq(slam.get_phase(), SlamAttack.Phase.RECOVERY)
	assert_false(slam.edge_marker.visible)
	assert_true(slam.shockwave.is_running())
	await wait_seconds(slam.shockwave.duration + 0.15)
	var expected := 100.0 - _boss.get_contact_damage() * slam.damage_factor
	assert_almost_eq(inside.get_current(), expected, 0.01, "una sola vez")
	assert_eq(outside.get_current(), 100.0, "fuera del aro no le da")
	var finished := false
	for _tick: int in 100:
		finished = slam.step(0.05, Vector3.ZERO)
		if finished:
			break
	assert_true(finished)
	assert_almost_eq(slam.arm.rotation.x, rest, 0.01, "vuelve a bajar la porra")


func test_cancelling_the_slam_clears_the_warning() -> void:
	var slam := _boss.get_node(^"Porrazo") as SlamAttack
	var rest := slam.arm.rotation.x
	slam.begin(Vector3.ZERO)
	slam.step(slam.windup * 0.5, Vector3.ZERO)
	slam.cancel()
	assert_false(slam.edge_marker.visible)
	assert_false(slam.charge_marker.visible)
	assert_almost_eq(slam.arm.rotation.x, rest, 0.001)


## Una hurtbox del jugador (capa [code]player_hurtbox[/code]) con 100 de vida, con los pies en
## [param at].
func _target(at: Vector3) -> HealthComponent:
	var stats := StatsComponent.new()
	var data := HealthData.new()
	data.max_health = 100.0
	stats.sources.append(data)
	add_child_autofree(stats)
	var health := HealthComponent.new()
	health.stats = stats
	health.rules = RULES
	add_child_autofree(health)
	var hurtbox := HurtboxComponent.new()
	hurtbox.collision_layer = PhysicsLayers.mask(PhysicsLayers.PLAYER_HURTBOX)
	hurtbox.collision_mask = 0
	hurtbox.health = health
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0.0, 0.9, 0.0)
	hurtbox.add_child(shape)
	add_child_autofree(hurtbox)
	hurtbox.global_position = at
	return health


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 60.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)
