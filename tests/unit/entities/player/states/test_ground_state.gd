extends GutTest
## GroundState: al quedarse sin suelo pasa al aire con coyote time.

const COYOTE_TIME := 0.1


func test_leaving_the_floor_starts_coyote_time() -> void:
	var move := MovementData.new()
	move.coyote_time = COYOTE_TIME
	var machine := StateMachine.new()
	add_child_autofree(machine)
	var ground := GroundState.new()
	var air := AirState.new()
	machine.add_child(ground)
	machine.add_child(air)
	machine.initial_state = ground
	var context := MovementContext.new()
	context.body = autofree(CharacterBody3D.new())
	context.move = move
	context.ground = ground
	context.air = air
	machine.start(context)
	machine.physics_update(1.0 / 60.0)
	assert_same(machine.current, air, "un cuerpo fuera del árbol no tiene suelo")
	assert_eq(context.coyote_left, COYOTE_TIME)
