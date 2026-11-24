class_name StateMachine
extends Node
## Máquina de estados: sus hijos State son los estados y hay uno activo cada vez. Su dueño la arranca
## con start y la avanza con physics_update.
##
## Además de las transiciones que piden los estados, atiende acciones (request), las pulse el jugador
## o una IA:
## [br]- Gana la primera que se puede hacer; entra una por tick y las demás esperan hasta caducar.
## [br]- Si varios estados responden a la misma acción, entra el de más prioridad.
## [br]- Un estado comprometido no se corta, salvo por los que cancelan o lo interrumpen.
## [br]- Lo pedido al final de un estado comprometido se guarda; lo pedido antes, se pierde.

## Cambió el estado activo. [param previous] es null al arrancar.
signal state_changed(previous: State, current: State)

## Estado al arrancar.
@export var initial_state: State

## Segundos que espera una pulsación que aún no puede ejecutarse. Lo pone el dueño desde sus
## datos.
var buffer_time: float = 0.0
## Segundos finales de un estado comprometido en los que una pulsación se guarda en vez de
## descartarse. Lo pone el dueño desde sus datos.
var committed_end_buffer: float = 0.0
## Estado activo.
var current: State

var _states_by_action: Dictionary[StringName, Array] = {}
var _pending: Array[PendingAction] = []
var _clock: float = 0.0
var _transitioning: bool = false


## Arranca la máquina: entrega [param context] a cada estado y entra en [member initial_state].
func start(context: Object) -> void:
	for child: Node in get_children():
		var state := child as State
		if state:
			_register(state, context)
	transition_to(initial_state)


## Avanza un tick: entra la acción que gane, se actualiza el estado activo y caducan las
## pulsaciones viejas (después de elegir, para que toda pulsación se evalúe al menos una vez).
func physics_update(delta: float) -> void:
	if current == null:
		return
	_clock += delta
	var requested := _pick_requested()
	_expire_pending()
	if requested:
		transition_to(requested)
	current.physics_update(delta)


## Pide una acción, como si se acabara de pulsar.
func request(action: StringName) -> void:
	var pending := PendingAction.new()
	pending.action = action
	pending.expires_at = _clock + buffer_time
	_pending.append(pending)


## Acciones que activan algún estado de esta máquina.
func get_trigger_actions() -> Array[StringName]:
	var actions: Array[StringName] = []
	actions.assign(_states_by_action.keys())
	return actions


## Cambia a [param next]; si ya es el activo, sale y vuelve a entrar. No se puede llamar desde
## [method State.enter] ni [method State.exit].
func transition_to(next: State) -> void:
	if next == null:
		push_error("StateMachine: transición a un estado nulo.")
		return
	if _transitioning:
		push_error("StateMachine: cambio de estado durante otro cambio (desde enter o exit).")
		return
	_transitioning = true
	var previous := current
	if previous:
		previous.exit(next)
	current = next
	next.enter(previous)
	_transitioning = false
	state_changed.emit(previous, next)


func _register(state: State, context: Object) -> void:
	state.machine = self
	state.setup(context)
	if state.trigger_action.is_empty():
		return
	var candidates: Array = _states_by_action.get_or_add(state.trigger_action, [])
	candidates.append(state)
	# Mayor prioridad primero; a igual prioridad, el orden del árbol, para que sea estable.
	candidates.sort_custom(
		func(a: State, b: State) -> bool:
			return a.priority > b.priority or (a.priority == b.priority and a.get_index() < b.get_index())
	)


func _pick_requested() -> State:
	var index := 0
	while index < _pending.size():
		var allowed := _allowed_states(_pending[index].action)
		if allowed.is_empty() and _is_committed_for_long():
			_pending.remove_at(index)
			continue
		for candidate: State in allowed:
			if candidate.can_enter():
				_pending.remove_at(index)
				return candidate
		index += 1
	return null


## Estados de [param action] que el estado activo deja entrar, por prioridad.
func _allowed_states(action: StringName) -> Array[State]:
	var allowed: Array[State] = []
	var candidates: Array = _states_by_action.get(action, [])
	for candidate: State in candidates:
		if _may_interrupt(candidate):
			allowed.append(candidate)
	return allowed


func _may_interrupt(candidate: State) -> bool:
	if current == null or not current.committed:
		return true
	return candidate.cancels_committed or candidate.interrupts.has(current)


func _is_committed_for_long() -> bool:
	return current != null and current.committed and current.time_left() > committed_end_buffer


func _expire_pending() -> void:
	for i: int in range(_pending.size() - 1, -1, -1):
		if _pending[i].expires_at < _clock:
			_pending.remove_at(i)


## Pulsación que espera su turno.
class PendingAction:
	var action: StringName
	var expires_at: float = 0.0
