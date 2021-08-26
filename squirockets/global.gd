extends Node


func instance_node_location(node : Object, parent : Object, location : Vector3) -> Object:
	var inst = instance_node(node,parent)
	inst.global_transform.origin = location
	return inst
	
func instance_node(node : Object, parent : Object) -> Object:
	var inst = node.instance()
	parent.add_child(inst)
	return inst
