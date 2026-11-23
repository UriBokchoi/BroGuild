extends GutTest
## Hacha, colonia y martillo con física real contra muñecos. El hacha atraviesa a todos a la ida y
## a la vuelta (también a los que pasan cerca de su filo) y, contra una pared, da la vuelta antes. La
## colonia daña a la vez a todos los de dentro de su aura (que crece con el área) y a nadie de fuera.
## El martillo cae sobre el grupo más denso a su alcance, no sobre el más cercano, y daña a todo el
## grupo.

const AXE := preload("res://data/weapons/axe.tres")
const COLOGNE := preload("res://data/weapons/cologne.tres")
const HAMMER := preload("res://data/weapons/hammer.tres")
const DummyScene := preload("res://entities/enemies/target_dummy/target_dummy.tscn")

var _offense: OffenseData
var _wielder: StatsComponent
var _inventory: WeaponInventory


func before_each() -> void:
	_offense = OffenseData.new()
	_offense.damage = 100.0
	_offense.crit_damage = 150.0
	_offense.attack_speed = 100.0
	_offense.projectile_speed = 100.0
	_offense.area = 100.0
	_offense.duration = 100.0
	_offense.knockback = 100.0
	_wielder = StatsComponent.new()
	_wielder.sources.append(_offense)
	add_child_autofree(_wielder)
	_inventory = WeaponInventory.new()
	_inventory.wielder_stats = _wielder
	add_child_autofree(_inventory)


func test_the_axe_pierces_everyone_on_the_way_out_and_back() -> void:
	var near := _dummy_health(Vector3(0.0, 0.0, -4.0))
	var far := _dummy_health(Vector3(0.0, 0.0, -8.0))
	var axe := _add_single_shot(AXE)
	await wait_seconds(axe.duration() + 0.6)
	assert_signal_emit_count(near, "damaged", 2, "a la ida y a la vuelta")
	assert_signal_emit_count(far, "damaged", 2, "la atraviesa: también al de detrás")


func test_the_axe_edge_cuts_what_passes_close() -> void:
	_dummy_health(Vector3(0.0, 0.0, -4.0))
	var beside := _dummy_health(Vector3(0.7, 0.0, -6.0))
	var away := _dummy_health(Vector3(4.0, 0.0, -6.0))
	var axe := _add_single_shot(AXE)
	await wait_seconds(axe.duration() + 0.6)
	assert_signal_emitted(beside, "damaged", "pasa a su lado: lo corta")
	assert_signal_not_emitted(away, "damaged", "lejos de su camino")


func test_the_axe_turns_back_at_a_wall_and_comes_home() -> void:
	_add_wall(Vector3(0.0, 1.0, -3.0))
	var front := _dummy_health(Vector3(0.0, 0.0, -2.0))
	var behind := _dummy_health(Vector3(0.0, 0.0, -7.0))
	var axe := _add_single_shot(AXE)
	await wait_seconds(axe.duration() + 0.6)
	assert_signal_emit_count(front, "damaged", 2)
	assert_signal_not_emitted(behind, "damaged", "la pared la hace volver")
	var flying := _descendants(axe).filter(func(node: Node) -> bool: return node is ThrowingAxe and (node as ThrowingAxe).visible)
	assert_true(flying.is_empty(), "ha vuelto a la mano")


func test_the_cologne_pulses_everyone_inside_and_nobody_outside() -> void:
	var inside := _dummy_health(Vector3(2.0, 0.0, 0.0))
	var other_side := _dummy_health(Vector3(-2.0, 0.0, 1.0))
	var outside := _dummy_health(Vector3(7.0, 0.0, 0.0))
	var cologne := _add_single_shot(COLOGNE) as CologneCloud
	await wait_physics_frames(3)
	assert_signal_emit_count(inside, "damaged", 1)
	assert_signal_emit_count(other_side, "damaged", 1, "alrededor, no solo delante")
	assert_signal_not_emitted(outside, "damaged", "fuera del aura")
	assert_gt(cologne.glow(), 0.0, "la nube se aviva")


func test_the_cologne_grows_with_area() -> void:
	var cologne := _add_single_shot(COLOGNE) as CologneCloud
	var base := cologne.reach()
	_wielder.add_modifier(StatModifier.create(&"area", StatModifier.Kind.PERCENT, 1.0), self)
	assert_almost_eq(cologne.reach(), base * 2.0, 0.001)


func test_the_hammer_falls_on_the_densest_group() -> void:
	var lone := _dummy_health(Vector3(0.0, 0.0, -5.0))
	var group: Array[HealthComponent] = [
		_dummy_health(Vector3(6.0, 0.0, -9.0)),
		_dummy_health(Vector3(7.0, 0.0, -9.5)),
		_dummy_health(Vector3(6.2, 0.0, -10.2)),
	]
	var hammer := _add_single_shot(HAMMER)
	var strikes := _descendants(hammer).filter(func(node: Node) -> bool: return node is HammerStrike)
	var strike := strikes[0] as HammerStrike
	await wait_seconds(strike.fall_time + 0.2)
	for health: HealthComponent in group:
		assert_signal_emit_count(health, "damaged", 1, "todo el grupo")
	assert_signal_not_emitted(lone, "damaged", "el más cercano está solo")


func test_densest_prefers_crowds_and_skips_the_same_group() -> void:
	var lone := _point(Vector3(1.0, 0.0, 0.0))
	var a := _point(Vector3(10.0, 0.0, 0.0))
	var b := _point(Vector3(11.0, 0.0, 0.0))
	var c := _point(Vector3(10.5, 0.0, 1.0))
	var chosen := WarHammer.densest([lone, a, b, c] as Array[Node3D], 2.0, 2)
	assert_true(chosen[0] in [a, b, c], "primero, el grupo")
	assert_eq(chosen[1], lone, "luego otro sitio, no el mismo grupo")


## Equipa [param data] con una espera enorme entre ataques: solo lanza su primer golpe.
func _add_single_shot(data: WeaponData) -> Weapon:
	_inventory.add(data)
	var weapon := _inventory.get_weapons()[0]
	weapon.stats.add_modifier(StatModifier.create(&"cooldown", StatModifier.Kind.MULTIPLIER, 1000.0), self)
	return weapon


func _dummy_health(at: Vector3) -> HealthComponent:
	var dummy := DummyScene.instantiate() as Node3D
	dummy.position = at
	add_child_autofree(dummy)
	var health := dummy.get_node(^"Health") as HealthComponent
	watch_signals(health)
	return health


func _point(at: Vector3) -> Node3D:
	var node := Node3D.new()
	add_child_autofree(node)
	node.global_position = at
	return node


func _add_wall(at: Vector3) -> void:
	var wall := StaticBody3D.new()
	wall.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	wall.position = at
	var box := BoxShape3D.new()
	box.size = Vector3(8.0, 4.0, 0.5)
	var shape := CollisionShape3D.new()
	shape.shape = box
	wall.add_child(shape)
	add_child_autofree(wall)


## Todos los nodos bajo [param root].
func _descendants(root: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in root.get_children():
		found.append(child)
		found.append_array(_descendants(child))
	return found
