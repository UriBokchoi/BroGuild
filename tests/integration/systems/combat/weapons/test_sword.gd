extends GutTest
## Espada e inventario de armas con física real: ataca sola al muñeco que está a su alcance, ignora
## lo que queda lejos, sus niveles aplican las mejoras de sus datos y las stats de quien la lleva
## escalan cadencia, tajos y alcance.

const SWORD := preload("res://data/weapons/sword.tres")
const DummyScene := preload("res://entities/enemies/target_dummy/target_dummy.tscn")

var _wielder: StatsComponent
var _inventory: WeaponInventory


func before_each() -> void:
	var offense := OffenseData.new()
	offense.damage = 100.0
	offense.crit_chance = 0.0
	offense.crit_damage = 150.0
	offense.attack_speed = 100.0
	offense.projectile_speed = 100.0
	offense.area = 100.0
	offense.duration = 100.0
	offense.knockback = 100.0
	_wielder = StatsComponent.new()
	_wielder.sources.append(offense)
	add_child_autofree(_wielder)
	_inventory = WeaponInventory.new()
	_inventory.wielder_stats = _wielder
	add_child_autofree(_inventory)


func test_inventory_holds_each_weapon_once() -> void:
	var sword := _inventory.add(SWORD)
	assert_true(sword is Sword)
	assert_null(_inventory.add(SWORD), "ya la lleva")
	assert_eq(_inventory.get_weapons().size(), 1)
	_inventory.remove(SWORD)
	assert_false(_inventory.has(SWORD))


func test_levels_add_and_remove_upgrades() -> void:
	var sword := _inventory.add(SWORD)
	sword.set_level(2)
	assert_eq(sword.damage(), 25.0, "la mejora estándar: +5 de daño")
	assert_eq(sword.projectile_count(), 2)
	assert_almost_eq(sword.cooldown(), 1.1 * 0.92, 1e-4)
	sword.set_level(99)
	assert_eq(sword.level, SWORD.max_level(), "no pasa del máximo")
	assert_eq(sword.get_upgrades().size(), SWORD.max_level() - 1)
	sword.set_level(1)
	assert_eq(sword.damage(), 20.0, "bajar de nivel quita las mejoras")
	assert_eq(sword.projectile_count(), 1)


func test_a_rolled_upgrade_adds_its_modifiers() -> void:
	var sword := _inventory.add(SWORD)
	var upgrade := ItemUpgrade.new()
	upgrade.stat_modifiers.append(StatModifier.create(&"damage", StatModifier.Kind.FLAT, 7.0))
	sword.add_upgrade(upgrade)
	assert_eq(sword.level, 2)
	assert_eq(sword.damage(), 27.0)


func test_wielder_stats_scale_the_weapon() -> void:
	var sword := _inventory.add(SWORD)
	_wielder.add_modifier(StatModifier.create(&"attack_speed", StatModifier.Kind.PERCENT, 1.0), self)
	_wielder.add_modifier(StatModifier.create(&"projectile_count", StatModifier.Kind.FLAT, 1.0), self)
	_wielder.add_modifier(StatModifier.create(&"area", StatModifier.Kind.PERCENT, 0.5), self)
	assert_almost_eq(sword.cooldown(), 0.55, 1e-4, "el doble de rápida")
	assert_eq(sword.projectile_count(), 2, "un tajo más")
	assert_almost_eq(sword.reach(), 4.2, 1e-4, "el área alarga el tajo")


func test_slashes_a_dummy_in_reach() -> void:
	var dummy := _add_dummy(Vector3(0.0, 0.0, -2.0))
	var health := dummy.get_node(^"Health") as HealthComponent
	watch_signals(health)
	_inventory.add(SWORD)
	await wait_physics_frames(15)
	assert_signal_emit_count(health, "damaged", 1, "un tajo, un golpe")
	var amount: float = get_signal_parameters(health, "damaged")[0]
	assert_eq(amount, 20.0)


func test_aims_up_at_a_dummy_above() -> void:
	# Por encima de la altura del tajo plano (la de una pila de enemigos).
	var dummy := _add_dummy(Vector3(0.0, 2.2, -1.2))
	var health := dummy.get_node(^"Health") as HealthComponent
	watch_signals(health)
	_inventory.add(SWORD)
	await wait_physics_frames(15)
	assert_signal_emitted(health, "damaged", "el tajo se inclina hacia él")


func test_ignores_dummies_out_of_reach() -> void:
	_add_dummy(Vector3(0.0, 0.0, -10.0))
	var sword := _inventory.add(SWORD)
	watch_signals(sword)
	await wait_physics_frames(15)
	assert_signal_not_emitted(sword, "fired")


func test_extra_projectiles_are_extra_slashes() -> void:
	var dummy := _add_dummy(Vector3(0.0, 0.0, -2.0))
	var health := dummy.get_node(^"Health") as HealthComponent
	watch_signals(health)
	var sword := _inventory.add(SWORD)
	sword.set_level(2)
	watch_signals(sword)
	await wait_physics_frames(20)
	assert_signal_emit_count(sword, "fired", 2)
	assert_signal_emit_count(health, "damaged", 2, "cada tajo golpea una vez")


func _add_dummy(at: Vector3) -> Node3D:
	var dummy := DummyScene.instantiate() as Node3D
	dummy.position = at
	add_child_autofree(dummy)
	return dummy
