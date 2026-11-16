extends RefCounted
## Monta lo necesario para probar estados de movimiento sin la escena del jugador: un cuerpo
## fuera del árbol (nunca está en el suelo), stamina real con sus stats y una máquina con los
## estados neutros Suelo y Aire.

## Contexto con [param move] y una stamina llena de [param max_charges] cargas.
static func create(test: GutTest, move: MovementData, max_charges: int = 3) -> MovementContext:
	var stamina_data := StaminaData.new()
	stamina_data.max_charges = max_charges
	stamina_data.recharge_time = 3.0
	var stats := StatsComponent.new()
	stats.sources.append(stamina_data)
	test.add_child_autofree(stats)
	var stamina := StaminaComponent.new()
	stamina.stats = stats
	test.add_child_autofree(stamina)
	var context := MovementContext.new()
	context.body = test.autofree(CharacterBody3D.new())
	context.move = move
	context.stamina = stamina
	return context


## Máquina arrancada en Aire con Suelo, Aire y [param states]; deja Suelo y Aire en el contexto.
static func start_machine(test: GutTest, context: MovementContext, states: Array[State]) -> StateMachine:
	var machine := StateMachine.new()
	test.add_child_autofree(machine)
	var ground := GroundState.new()
	var air := AirState.new()
	machine.add_child(ground)
	machine.add_child(air)
	for state: State in states:
		machine.add_child(state)
	context.ground = ground
	context.air = air
	machine.initial_state = air
	machine.start(context)
	return machine


## Datos con un salto razonable, para que la gravedad del estado Aire esté definida.
static func movement_with_gravity() -> MovementData:
	var move := MovementData.new()
	move.jump_height = 2.0
	move.jump_time_to_apex = 0.5
	move.max_fall_speed = 50.0
	return move
