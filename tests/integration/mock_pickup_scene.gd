# mock_pickup_scene.gd
extends Resource

func instantiate() -> Node:
	var node = Area3D.new()
	node.set_script(load("res://src/gameplay/loot/loot_pickup.gd"))
	node.add_to_group("mock_pickups")
	return node
