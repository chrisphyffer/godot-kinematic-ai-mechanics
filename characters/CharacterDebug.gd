extends Node

class_name CharacterDebug

func draw_line(start, end, color, existingDrawNode:Node = null):
	
	var draw_path_node = null
	var _m = SpatialMaterial.new()
	_m.albedo_color = color
	_m.flags_unshaded = true
	_m.flags_use_point_size = true

	if existingDrawNode:
		draw_path_node = existingDrawNode
	else:
		draw_path_node = ImmediateGeometry.new()

	draw_path_node.set_material_override(_m)
	draw_path_node.clear()
	#draw_path_node.begin(Mesh.PRIMITIVE_POINTS, null)

	#draw_path_node.add_vertex(Vector3(navigation_path[0].x, navigation_path[0].y, navigation_path[0].z ) )
	#draw_path_node.add_vertex(Vector3(navigation_path[navigation_path.size()-1].x, navigation_path[navigation_path.size()-1].y, navigation_path[navigation_path.size()-1].z ) )
	#draw_path_node.end()

	draw_path_node.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	draw_path_node.add_vertex(start )
	draw_path_node.add_vertex(end )
	
	draw_path_node.end()
	
	if not existingDrawNode:
		get_parent().add_child(draw_path_node)

	return draw_path_node