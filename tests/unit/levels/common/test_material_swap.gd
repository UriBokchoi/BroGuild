extends GutTest
## MaterialSwap: cambia los materiales de la lista en todas las mallas (el de la superficie y el que
## tapa toda la malla, también en los hijos) y deja los demás como estaban.

var _grass := StandardMaterial3D.new()
var _snow := StandardMaterial3D.new()
var _other := StandardMaterial3D.new()


func test_swaps_the_listed_materials_and_leaves_the_rest() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.material = _grass
	ground.mesh = plane
	root.add_child(ground)
	var child := Node3D.new()
	root.add_child(child)
	var covered := MeshInstance3D.new()
	covered.mesh = BoxMesh.new()
	covered.material_override = _grass
	child.add_child(covered)
	var untouched := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.material = _other
	untouched.mesh = box
	root.add_child(untouched)
	var swaps: Dictionary[Material, Material] = {_grass: _snow}
	assert_eq(MaterialSwap.apply(root, swaps), 2)
	assert_eq(ground.get_active_material(0), _snow, "el de la superficie")
	assert_eq(covered.material_override, _snow, "el que tapa la malla, en un hijo")
	assert_eq(untouched.get_active_material(0), _other, "los demás, igual")
	assert_eq(plane.material, _grass, "la malla compartida no cambia")
