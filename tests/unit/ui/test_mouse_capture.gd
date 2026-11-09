extends GutTest
## MouseCapture: el cursor se muestra mientras alguna interfaz lo pida.

var _capture: MouseCapture


func before_each() -> void:
	_capture = MouseCapture.new()
	add_child_autofree(_capture)


func after_each() -> void:
	# Al lanzar los tests desde el editor, que no se quede el ratón capturado.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_captured_until_someone_asks_for_the_cursor() -> void:
	assert_false(_capture.is_cursor_requested())
	var menu := RefCounted.new()
	EventBus.cursor_requested.emit(menu, true)
	assert_true(_capture.is_cursor_requested())
	EventBus.cursor_requested.emit(menu, false)
	assert_false(_capture.is_cursor_requested())


func test_cursor_stays_while_any_requester_wants_it() -> void:
	var menu := RefCounted.new()
	var panel := RefCounted.new()
	EventBus.cursor_requested.emit(menu, true)
	EventBus.cursor_requested.emit(panel, true)
	EventBus.cursor_requested.emit(menu, false)
	assert_true(_capture.is_cursor_requested(), "el panel aún lo pide")
	EventBus.cursor_requested.emit(panel, false)
	assert_false(_capture.is_cursor_requested())
