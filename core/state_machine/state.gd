@abstract
class_name State
extends Node
## Estado de una [StateMachine]: un nodo hijo de su máquina con su propio script. Añadir un
## estado no obliga a tocar los demás.
##
## Se entra en un estado por su acción ([member trigger_action]) o porque otro estado pide
## pasar a él con [method StateMachine.transition_to]. Las reglas de las acciones están en
## [StateMachine]; cada estado solo declara aquí cómo participa en ellas.

## Acción que lo activa (p. ej. [code]&"jump"[/code]). Vacía: solo se entra por transición.
@export var trigger_action: StringName = &""
## Entre estados de la misma acción se prueba primero el de mayor prioridad.
@export var priority: int = 0
## Mientras está activo, ninguna acción puede activar otro estado, salvo los que cancelan
## ([member cancels_committed]) o los que lo listan en [member interrupts].
@export var committed: bool = false
## Entra aunque el estado activo esté comprometido (el dash cancela cualquier acción).
@export var cancels_committed: bool = false
## Estados comprometidos que este puede interrumpir (p. ej. el slide-jump interrumpe el slide).
## Es [code]Array[Node][/code] y no [code]Array[State][/code] a propósito: un array tipado
## con su propia clase hace que el script se referencie a sí mismo y Godot no lo libera
## (comprobado en 4.7.2).
@export var interrupts: Array[Node] = []

## Máquina a la que pertenece. La asigna la máquina al arrancar.
var machine: StateMachine


## Recibe el contexto que comparten los estados de su máquina. Se llama una vez, al arrancar.
func setup(_context: Object) -> void:
	pass


## ¿Puede entrar ahora? La máquina lo pregunta antes de activarlo por su acción.
func can_enter() -> bool:
	return true


## Al entrar. No cambies de estado aquí: hazlo en [method physics_update].
func enter(_previous: State) -> void:
	pass


## Al salir. No cambies de estado aquí.
func exit(_next: State) -> void:
	pass


## Un tick de física mientras está activo.
func physics_update(_delta: float) -> void:
	pass


## Segundos que le quedan si termina solo (un dash, por ejemplo); [constant @GDScript.INF] si no.
func time_left() -> float:
	return INF
