extends GutTest
## Destello al golpear: un golpe pone la capa blanca en el cuerpo del enemigo (no en los ojos), se apaga sola
## al poco y deja la capa que hubiera (el brillo de un élite); cada golpe la vuelve a encender.

const SWARMER := preload("res://data/enemies/swarmer.tres")
const ELITE := preload("res://data/enemies/elite.tres")
const FLASH := preload("res://vfx/juice/hit_flash/hit_flash_material.tres")

var _swarm: EnemySwarm


func before_each() -> void:
	_swarm = EnemySwarm.new()
	add_child_autofree(_swarm)


func test_a_hit_flashes_white_and_fades() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	var flash := enemy.get_node(^"HitFlash") as HitFlash
	enemy.health.take_damage(DamageInfo.create(1.0))
	assert_true(flash.is_flashing())
	for mesh: GeometryInstance3D in _meshes(enemy):
		assert_eq(mesh.material_overlay, FLASH, "%s, blanca" % mesh.name)
	await wait_seconds(flash.duration + 0.1)
	assert_false(flash.is_flashing())
	for mesh: GeometryInstance3D in _meshes(enemy):
		assert_null(mesh.material_overlay, "vuelve a como estaba")


func test_an_elite_keeps_its_glow_after_the_flash() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	enemy.promote(ELITE)
	var flash := enemy.get_node(^"HitFlash") as HitFlash
	enemy.health.take_damage(DamageInfo.create(1.0))
	flash.stop()
	for mesh: GeometryInstance3D in _meshes(enemy):
		assert_eq(mesh.material_overlay, ELITE.overlay)


func test_another_hit_lights_it_again() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	var flash := enemy.get_node(^"HitFlash") as HitFlash
	enemy.health.take_damage(DamageInfo.create(1.0))
	await wait_seconds(flash.duration * 0.7)
	enemy.health.take_damage(DamageInfo.create(1.0))
	await wait_seconds(flash.duration * 0.7)
	assert_true(flash.is_flashing(), "el segundo golpe alarga el destello")


## Las mallas que se iluminan (las del destello del enemigo: su cuerpo).
func _meshes(enemy: Enemy) -> Array[GeometryInstance3D]:
	return (enemy.get_node(^"HitFlash") as HitFlash).meshes


func test_only_the_body_lights_up() -> void:
	var enemy := _swarm.spawn(SWARMER, Vector3.ZERO)
	enemy.health.take_damage(DamageInfo.create(1.0))
	var lit := 0
	for mesh: Node in enemy.visual.find_children("*", "GeometryInstance3D", true, false):
		if (mesh as GeometryInstance3D).material_overlay == FLASH:
			lit += 1
	assert_eq(lit, _meshes(enemy).size(), "solo las del destello")
	assert_gt(_meshes(enemy).size(), 0)
