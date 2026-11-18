extends GutTest
## Shockwave con física real: se abre por el suelo hasta su radio y daña una sola vez a lo que
## alcanza su borde; lo que está más alto (saltándola) o más lejos que su radio no recibe nada; al
## terminar se apaga.

const WaveScene := preload("res://entities/enemies/boss/shockwave/shockwave.tscn")
const RULES := preload("res://data/combat/rules.tres")

var _wave: Shockwave


func before_each() -> void:
	_wave = WaveScene.instantiate() as Shockwave
	add_child_autofree(_wave)


func test_hits_once_what_its_edge_reaches_on_the_ground() -> void:
	var near := _target(Vector3(5.0, 0.0, 0.0))
	var jumping := _target(Vector3(0.0, 3.0, 5.0))
	var far := _target(Vector3(_wave.radius + 6.0, 0.0, 0.0))
	await wait_physics_frames(2)
	_wave.start(Vector3.ZERO, 30.0)
	assert_true(_wave.is_running())
	await wait_seconds(_wave.duration + 0.2)
	assert_almost_eq(near.get_current(), 70.0, 0.01, "una sola vez")
	assert_eq(jumping.get_current(), 100.0, "la salta")
	assert_eq(far.get_current(), 100.0, "fuera de su alcance")
	assert_false(_wave.is_running())
	assert_false(_wave.visible)


## Una hurtbox de jugador (capa [code]player_hurtbox[/code]) con 100 de vida, con los pies en
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
	hurtbox.collision_layer = 8
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
