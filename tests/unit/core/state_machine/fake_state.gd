extends State
## Estado de prueba para los tests de StateMachine: se configura desde el test y cuenta
## cuántas veces entra, sale y se actualiza.

## Lo que responde can_enter().
var allow_enter: bool = true
## Lo que responde time_left().
var remaining: float = INF
## Si no es null, intenta cambiar a este estado dentro de enter() (no está permitido).
var redirect_on_enter: State
var entered: int = 0
var exited: int = 0
var updates: int = 0


func can_enter() -> bool:
	return allow_enter


func enter(_previous: State) -> void:
	entered += 1
	if redirect_on_enter:
		machine.transition_to(redirect_on_enter)


func exit(_next: State) -> void:
	exited += 1


func physics_update(_delta: float) -> void:
	updates += 1


func time_left() -> float:
	return remaining
