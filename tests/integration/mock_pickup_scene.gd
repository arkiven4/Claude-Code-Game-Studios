# mock_pickup_scene.gd
extends Resource

func instantiate() -> Node:
	var script = GDScript.new()
	script.source_code = "extends Node3D\nvar item\n"
	script.reload()
	
	var node = Node3D.new()
	node.set_script(script)
	node.add_to_group("mock_pickups")
	return node
