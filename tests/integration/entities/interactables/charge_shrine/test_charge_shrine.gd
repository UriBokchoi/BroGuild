extends GutTest
## Pesa-santuario: con el jugador dentro de su zona se carga; al llenarse ofrece elegir una mejora de
## stats (una vez) y se apaga. Si el jugador sale, la carga se queda donde estaba.

const ShrineScene := preload("res://levels/brosque/props/dumbbell_shrine.tscn")
const PlayerScene := preload("res://entities/player/player.tscn")

var _shrine: ChargeShrine
var _player: Player
var _offers: Array = []


func before_each() -> void:
	_offers.clear()
	EventBus.stat_choice_offered.connect(_on_offered)
	_add_floor()
	_shrine = ShrineScene.instantiate() as ChargeShrine
	_shrine.data = _shrine.data.duplicate()
	_shrine.data.charge_time = 0.4
	add_child_autofree(_shrine)
	_player = PlayerScene.instantiate() as Player
	add_child_autofree(_player)
	_player.global_position = Vector3(30.0, 0.0, 0.0)


func after_each() -> void:
	EventBus.stat_choice_offered.disconnect(_on_offered)


func test_standing_inside_charges_it_and_offers_once() -> void:
	_player.global_position = Vector3(_shrine.data.reach - 1.0, 0.0, 0.0)
	await wait_seconds(0.2)
	assert_gt(_shrine.get_charge(), 0.0, "se carga")
	assert_eq(_offers.size(), 0, "aún no")
	await wait_seconds(0.4)
	assert_eq(_offers.size(), 1, "lleno: ofrece")
	assert_eq((_offers[0] as Array).size(), _shrine.data.choices)
	assert_true(_shrine.is_used())
	assert_false(_shrine.glow.visible, "se apaga")
	await wait_seconds(0.5)
	assert_eq(_offers.size(), 1, "una sola vez")


func test_leaving_keeps_the_charge() -> void:
	_player.global_position = Vector3(1.0, 0.0, 0.0)
	await wait_seconds(0.2)
	_player.global_position = Vector3(30.0, 0.0, 0.0)
	await wait_physics_frames(3)
	var kept := _shrine.get_charge()
	assert_gt(kept, 0.0)
	await wait_seconds(0.3)
	assert_almost_eq(_shrine.get_charge(), kept, 0.001, "fuera, ni sube ni baja")
	assert_eq(_offers.size(), 0)


func _on_offered(offers: Array[StatOffer]) -> void:
	_offers.append(offers)


## Un suelo grande: sin él, el jugador cae y sale de la zona.
func _add_floor() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	ground.position = Vector3(0.0, -0.5, 0.0)
	var box := BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
