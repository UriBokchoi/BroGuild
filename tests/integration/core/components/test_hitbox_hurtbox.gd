extends GutTest
## Hitbox y hurtbox con física real: al tocarse, la hitbox daña a la vida de la hurtbox, una vez o
## repitiendo cada cierto tiempo, y lo empuja desde la hitbox hacia la hurtbox.

const PLAYER_HURTBOX := 8
const MAX_HEALTH := 100.0

var _health: HealthComponent
var _hurtbox: HurtboxComponent


func before_each() -> void:
	var data := HealthData.new()
	data.max_health = MAX_HEALTH
	var stats := StatsComponent.new()
	stats.sources.append(data)
	add_child_autofree(stats)
	var rules := CombatRules.new()
	rules.armor_for_half_damage = 100.0
	_health = HealthComponent.new()
	_health.stats = stats
	_health.rules = rules
	add_child_autofree(_health)
	_hurtbox = HurtboxComponent.new()
	_hurtbox.collision_layer = PLAYER_HURTBOX
	_hurtbox.collision_mask = 0
	_hurtbox.health = _health
	_hurtbox.add_child(_box_shape())
	add_child_autofree(_hurtbox)


func test_touching_hitbox_damages_once_without_rehit() -> void:
	var hitbox := _add_hitbox(10.0, 0.0)
	watch_signals(hitbox)
	await wait_physics_frames(20)
	assert_eq(_health.get_current(), MAX_HEALTH - 10.0, "un solo golpe")
	assert_signal_emit_count(hitbox, "hit", 1)


func test_the_hit_pushes_away_from_the_hitbox() -> void:
	var hitbox := _add_hitbox(10.0, 0.0)
	hitbox.knockback = 5.0
	hitbox.position = Vector3(-0.3, 0.0, 0.0)
	var pushes: Array[Vector3] = []
	_hurtbox.hurt.connect(func(info: DamageInfo, _amount: float) -> void: pushes.append(info.knockback))
	await wait_physics_frames(10)
	assert_eq(pushes.size(), 1)
	assert_almost_eq(pushes[0], Vector3(5.0, 0.0, 0.0), Vector3.ONE * 0.001, "hacia +X, lejos de la hitbox")


func test_contact_damage_repeats_every_interval() -> void:
	_add_hitbox(10.0, 0.1)
	await wait_physics_frames(40)
	assert_lt(_health.get_current(), MAX_HEALTH - 10.0, "varios golpes mientras toca")


func test_hitbox_ignores_layers_outside_its_mask() -> void:
	var hitbox := _add_hitbox(10.0, 0.0)
	hitbox.collision_mask = 16
	await wait_physics_frames(20)
	assert_eq(_health.get_current(), MAX_HEALTH)


func test_hitbox_without_monitoring_does_not_hit() -> void:
	var hitbox := _add_hitbox(10.0, 0.0)
	hitbox.monitoring = false
	await wait_physics_frames(20)
	assert_eq(_health.get_current(), MAX_HEALTH)


func test_reset_hits_lets_a_new_attack_hit_again() -> void:
	var hitbox := _add_hitbox(10.0, 0.0)
	await wait_physics_frames(20)
	hitbox.reset_hits()
	await wait_physics_frames(4)
	assert_eq(_health.get_current(), MAX_HEALTH - 20.0, "un golpe por ataque")


func _add_hitbox(damage: float, rehit: float) -> HitboxComponent:
	var hitbox := HitboxComponent.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = PLAYER_HURTBOX
	hitbox.base_damage = damage
	hitbox.rehit_interval = rehit
	hitbox.add_child(_box_shape())
	add_child_autofree(hitbox)
	return hitbox


func _box_shape() -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE
	shape.shape = box
	return shape
