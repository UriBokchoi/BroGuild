extends GutTest
## Escena del jugador: montaje (capas, cámara, máquina de estados, vida) y caída hasta el suelo.

const PlayerScene := preload("res://entities/player/player.tscn")
const SPAWN_HEIGHT := 2.0

var _player: Player


func before_each() -> void:
	_add_ground()
	_player = PlayerScene.instantiate() as Player
	_player.position = Vector3(0.0, SPAWN_HEIGHT, 0.0)
	add_child_autofree(_player)


func test_body_is_the_player_and_collides_with_the_world() -> void:
	assert_eq(_player.collision_layer, PhysicsLayers.mask(PhysicsLayers.PLAYER))
	assert_eq(_player.collision_mask, PhysicsLayers.mask(PhysicsLayers.WORLD))


func test_camera_follows_the_player_and_only_collides_with_the_world() -> void:
	var rig := _player.get_node(^"CameraRig") as CameraRig
	assert_same(rig.target, _player)
	var arm := rig.get_node(^"%SpringArm3D") as SpringArm3D
	assert_eq(arm.collision_mask, PhysicsLayers.mask(PhysicsLayers.WORLD))


func test_has_survival_offense_progression_and_movement_stats() -> void:
	for type: Script in [HealthData, OffenseData, ProgressionData, MovementData, StaminaData]:
		assert_not_null(_player.stats.get_resolved(type), "faltan los datos de %s" % type.get_global_name())
	assert_eq(_player.stats.get_value(&"damage"), 100.0, "el daño empieza en el 100 %")
	assert_eq(_player.stats.get_value(&"crit_chance"), 5.0)


func test_falls_and_lands_on_the_ground() -> void:
	assert_same(_player.movement.current, _player.air_state, "empieza en el aire")
	await wait_physics_frames(60)
	assert_true(_player.is_on_floor(), "ha aterrizado")
	assert_same(_player.movement.current, _player.ground_state)
	assert_almost_eq(_player.global_position.y, 0.0, 0.05)


func test_hurtbox_only_receives_damage_on_its_layer() -> void:
	var hurtbox := _player.get_node(^"Hurtbox") as HurtboxComponent
	assert_eq(hurtbox.collision_layer, PhysicsLayers.mask(PhysicsLayers.PLAYER_HURTBOX))
	assert_eq(hurtbox.collision_mask, 0, "no detecta nada; las hitbox la detectan a ella")
	assert_same(hurtbox.health, _player.health)


func test_starts_with_full_health_and_tells_the_hud() -> void:
	assert_eq(_player.health.get_current(), 100.0)
	watch_signals(EventBus)
	_player.health.take_damage(DamageInfo.create(25.0))
	assert_signal_emitted_with_parameters(EventBus, "player_health_changed", [75.0, 100.0])


func test_dying_stops_the_player_and_tells_everyone() -> void:
	watch_signals(EventBus)
	_player.health.take_damage(DamageInfo.create(1000.0))
	assert_signal_emitted(EventBus, "player_died")
	assert_false(_player.is_physics_processing(), "se queda quieto")
	assert_eq(_player.velocity, Vector3.ZERO)


func test_weapons_use_the_player_stats() -> void:
	assert_same(_player.weapons.wielder_stats, _player.stats)


func test_interactor_only_detects_interactables() -> void:
	var interactor := _player.get_node(^"Interactor") as Interactor
	assert_eq(interactor.collision_layer, 0)
	assert_eq(interactor.collision_mask, PhysicsLayers.mask(PhysicsLayers.INTERACTABLE))
	assert_same(interactor.body, _player)


func test_teleport_places_the_player_stopped() -> void:
	_player.velocity = Vector3(5.0, 0.0, 5.0)
	_player.teleport_to(Vector3(3.0, 0.0, 4.0))
	assert_eq(_player.global_position, Vector3(3.0, 0.0, 4.0))
	assert_eq(_player.velocity, Vector3.ZERO)


func test_dying_stops_the_weapons() -> void:
	_player.health.take_damage(DamageInfo.create(1000.0))
	assert_eq(_player.weapons.process_mode, Node.PROCESS_MODE_DISABLED)


func test_hurtbox_lowers_while_sliding() -> void:
	await wait_physics_frames(60)
	var shape := _player.get_node(^"Hurtbox/CollisionShape3D") as CollisionShape3D
	var capsule := shape.shape as CapsuleShape3D
	var standing := capsule.height
	_player.movement.transition_to(_player.get_node(^"Movement/Slide") as State)
	assert_lt(capsule.height, standing, "agachado en el slide")
	assert_lt(shape.position.y, standing / 2.0, "baja con la cápsula")
	_player.movement.transition_to(_player.ground_state)
	assert_eq(capsule.height, standing, "de pie al salir")


func _add_ground() -> void:
	var ground := StaticBody3D.new()
	ground.collision_layer = PhysicsLayers.mask(PhysicsLayers.WORLD)
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 1.0, 20.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)
