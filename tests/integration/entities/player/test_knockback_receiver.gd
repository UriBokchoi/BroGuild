extends GutTest
## Empuje del jugador: un golpe que le hace daño lo desplaza hacia donde empuja y se frena solo.

const PlayerScene := preload("res://entities/player/player.tscn")


func test_a_hit_pushes_the_player_and_fades() -> void:
	RunState.character = null
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 60.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	ground.add_child(shape)
	add_child_autofree(ground)
	var player := PlayerScene.instantiate() as Player
	add_child_autofree(player)
	await wait_physics_frames(4)
	var start := player.global_position
	var hurtbox := player.get_node(^"Hurtbox") as HurtboxComponent
	hurtbox.receive(DamageInfo.create(5.0, false, null, Vector3(10.0, 0.0, 0.0)))
	var receiver := player.get_node(^"KnockbackReceiver") as KnockbackReceiver
	assert_gt(receiver.get_push().x, 0.0)
	await wait_seconds(0.5)
	assert_gt(player.global_position.x - start.x, 0.5, "se desplaza hacia donde empuja")
	assert_true(receiver.get_push().is_zero_approx(), "y se frena solo")
