class_name NodePool
extends RefCounted
## Reserva de nodos que se reutilizan en vez de crearse y liberarse cada vez (CLAUDE.md, regla 10):
## números de daño, proyectiles, enemigos… Los nodos se crean con [member factory], se añaden a
## [member parent] y se quedan ahí: [method acquire] da uno libre y [method release] lo devuelve.
## Quien los usa se encarga de mostrarlos y ocultarlos.

## Crea un nodo nuevo cuando no queda ninguno libre. Devuelve un [Node].
var factory: Callable
## Nodo bajo el que viven los del pool.
var parent: Node

var _free: Array[Node] = []
var _created: int = 0


func _init(node_factory: Callable, pool_parent: Node) -> void:
	factory = node_factory
	parent = pool_parent


## Crea [param count] nodos de antemano, para no hacerlo en mitad del combate.
func prewarm(count: int) -> void:
	for _node: int in count:
		_free.append(_create())


## Un nodo libre (lo crea si no queda ninguno).
func acquire() -> Node:
	if _free.is_empty():
		return _create()
	return _free.pop_back()


## Devuelve [param node] al pool para reutilizarlo.
func release(node: Node) -> void:
	if not _free.has(node):
		_free.append(node)


## Nodos creados en total (libres y en uso).
func size() -> int:
	return _created


## Nodos libres ahora mismo.
func free_count() -> int:
	return _free.size()


func _create() -> Node:
	var node: Node = factory.call()
	parent.add_child(node)
	_created += 1
	return node
