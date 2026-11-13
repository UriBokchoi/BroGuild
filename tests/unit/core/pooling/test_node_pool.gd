extends GutTest
## NodePool: crea nodos solo cuando no quedan libres y reutiliza los devueltos.

var _parent: Node
var _pool: NodePool


func before_each() -> void:
	_parent = Node.new()
	add_child_autofree(_parent)
	_pool = NodePool.new(Node.new, _parent)


func test_prewarm_creates_free_nodes_under_the_parent() -> void:
	_pool.prewarm(3)
	assert_eq(_pool.size(), 3)
	assert_eq(_pool.free_count(), 3)
	assert_eq(_parent.get_child_count(), 3)


func test_acquire_creates_only_when_empty() -> void:
	var first := _pool.acquire()
	assert_eq(_pool.size(), 1)
	_pool.release(first)
	assert_same(_pool.acquire(), first, "reutiliza el devuelto")
	assert_eq(_pool.size(), 1)
	_pool.acquire()
	assert_eq(_pool.size(), 2, "sin libres, crea otro")


func test_releasing_twice_does_not_duplicate() -> void:
	var node := _pool.acquire()
	_pool.release(node)
	_pool.release(node)
	assert_eq(_pool.free_count(), 1)
