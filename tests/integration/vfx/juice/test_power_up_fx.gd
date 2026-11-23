extends GutTest
## Efectos de los power-ups: al coger uno, su efecto sale en el suelo bajo el jugador (también si lo
## coge en el aire), con su temblor y su destello; la bomba, como una explosión nuclear que llega tan
## lejos como su daño. Lo que no es un power-up no saca nada.

const FxScene := preload("res://vfx/juice/power_up_fx/power_up_fx.tscn")
const SystemsScene := preload("res://levels/common/run_systems.tscn")

var _fx: PowerUpFx
var _anchor: Node3D
var _shake: ScreenShake


func before_each() -> void:
	_add_floor()
	_anchor = Node3D.new()
	add_child_autofree(_anchor)
	_anchor.global_position = Vector3(3.0, 2.0, -1.0)
	var camera := Camera3D.new()
	add_child_autofree(camera)
	_shake = ScreenShake.new()
	_shake.camera = camera
	_shake.decay = 0.01
	add_child_autofree(_shake)
	_fx = FxScene.instantiate() as PowerUpFx
	_fx.anchor = _anchor
	_fx.shake = _shake
	add_child_autofree(_fx)


func test_every_power_up_has_its_effect() -> void:
	for reward: StringName in [&"bomb", &"magnet", &"heal", &"energy", &"time_stop"]:
		assert_not_null(_fx.get_burst(reward), "%s" % reward)
	assert_null(_fx.get_burst(&"gold"), "el oro no")


func test_the_bomb_goes_off_on_the_ground_with_shake_and_flash() -> void:
	await wait_physics_frames(2)
	EventBus.pickup_collected.emit(&"bomb", 0.5)
	var nuke := _fx.get_burst(&"bomb")
	assert_true(nuke.is_playing())
	assert_almost_eq(nuke.global_position, Vector3(3.0, 0.0, -1.0), Vector3.ONE * 0.01, "en el suelo, bajo el jugador en el aire")
	assert_gt(_shake.get_trauma(), 0.0, "tiembla")
	assert_true(_fx.flash.visible, "destello")
	await wait_seconds(nuke.flash_time + 0.1)
	assert_false(_fx.flash.visible, "y se va")


func test_other_rewards_do_nothing() -> void:
	EventBus.pickup_collected.emit(&"gold", 5.0)
	for reward: StringName in [&"bomb", &"magnet", &"heal", &"energy", &"time_stop"]:
		assert_false(_fx.get_burst(reward).is_playing())
	assert_false(_fx.flash.visible)


func test_the_nuke_wave_reaches_as_far_as_the_bomb() -> void:
	var systems := SystemsScene.instantiate()
	var bomb := systems.get_node(^"PickupEffects/Bomb") as BombEffect
	var fx := systems.get_node(^"PowerUpFx") as PowerUpFx
	var nuke := fx.effects[&"bomb"].instantiate() as FxBurst
	assert_eq(nuke.ring_radius, bomb.radius)
	assert_same(fx.anchor, systems.get_node(^"Player"))
	nuke.free()
	systems.free()


func _add_floor() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	ground.position = Vector3(0.0, -0.5, 0.0)
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 1.0, 20.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
