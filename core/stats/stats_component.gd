class_name StatsComponent
extends Node
## Stats de una entidad. Convierte en stats los números exportados de sus Resources de datos
## (ver [method StatBlock.define_from_resource]) y mantiene una copia «resuelta» de cada uno
## con los modificadores ya aplicados, para leerla con tipo:
## [codeblock]
## var move := stats.get_resolved(MovementData) as MovementData
## velocity = direction * move.run_speed
## [/codeblock]
## Las stats existen desde que el nodo entra en el árbol, antes de cualquier
## [code]_ready[/code]: cualquier nodo de la escena puede leerlas en el suyo, esté donde esté.

## Cambió una stat. Cuando llega, la copia resuelta ya tiene el valor nuevo.
signal stat_changed(stat: StringName, value: float, previous: float)

## Resources de datos de la entidad (su MovementData, etc.). Nunca se modifican: el juego lee
## las copias resueltas. Cada stat debe venir de un solo Resource.
@export var sources: Array[Resource] = []

var _block := StatBlock.new()
var _resolved: Array[Resource] = []
var _resolved_by_stat: Dictionary[StringName, Resource] = {}
var _registered: bool = false


func _enter_tree() -> void:
	# En _enter_tree y no en _ready: así el orden de los nodos hermanos no importa.
	if _registered:
		return
	_registered = true
	_block.stat_changed.connect(_on_block_stat_changed)
	for source: Resource in sources:
		_register(source)


## Copia resuelta del Resource de datos de tipo [param type] (o de un subtipo).
func get_resolved(type: Script) -> Resource:
	for copy: Resource in _resolved:
		if is_instance_of(copy, type):
			return copy
	push_error("StatsComponent: no hay datos de tipo '%s'." % type.resource_path)
	return null


## Valor final de [param stat]. Para leer con tipo, mejor [method get_resolved].
func get_value(stat: StringName) -> float:
	return _block.get_value(stat)


## Ver [method StatBlock.get_base].
func get_base(stat: StringName) -> float:
	return _block.get_base(stat)


## Ver [method StatBlock.get_stats].
func get_stats() -> Array[StringName]:
	return _block.get_stats()


## Ver [method StatBlock.add_modifier].
func add_modifier(modifier: StatModifier, source: Object) -> void:
	_block.add_modifier(modifier, source)


## Ver [method StatBlock.remove_modifiers_from].
func remove_modifiers_from(source: Object) -> void:
	_block.remove_modifiers_from(source)


func _register(source: Resource) -> void:
	if source == null:
		push_error("StatsComponent: hay un hueco vacío en 'sources'.")
		return
	var copy := source.duplicate()
	_resolved.append(copy)
	for stat: StringName in _block.define_from_resource(source):
		_resolved_by_stat[stat] = copy
		# El valor puede no ser la base si queda fuera de los límites.
		copy.set(stat, _block.get_value(stat))


func _on_block_stat_changed(stat: StringName, value: float, previous: float) -> void:
	# set() convierte el float a int en las propiedades enteras (comprobado en 4.7.2).
	_resolved_by_stat[stat].set(stat, value)
	stat_changed.emit(stat, value, previous)
