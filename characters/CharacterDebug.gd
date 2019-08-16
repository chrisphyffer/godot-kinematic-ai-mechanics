extends Node

class_name CharacterDebug

#https://godotengine.org/qa/3843/is-it-possible-to-draw-a-circular-arc
func draw_circle_arc( center, radius, angleFrom:float=0.0, angleTo:float=359.0, color:Color=Color(1,1,1,1) ):
	var nbPoints = 32
	
	print('DRAWING CIRCLE ARC')
	
	var _m = SpatialMaterial.new()
	_m.albedo_color = color
	_m.flags_unshaded = true
	_m.flags_use_point_size = true
	var draw_path_node = ImmediateGeometry.new()
	
	draw_path_node.set_material_override(_m)
	draw_path_node.clear()
	draw_path_node.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	
	for i in range(nbPoints+1):
		var anglePoint = angleFrom + i*(angleTo-angleFrom)/nbPoints - 90
		var point = center + Vector3( cos(deg2rad(anglePoint)), 0, sin(deg2rad(anglePoint)) ) * radius
		draw_path_node.add_vertex(point)
		print(point)
	
	draw_path_node.end()

func draw_circle_arc_poly( center, radius, angleFrom, angleTo, color ):
	var nbPoints = 32
	var pointsArc = Vector2()
	pointsArc.push_back(center)
	var colors = Color()
	
	for i in range(nbPoints+1):
	    var anglePoint = angleFrom + i*(angleTo-angleFrom)/nbPoints - 90
	    pointsArc.push_back(center + Vector2( cos( deg2rad(anglePoint) ), sin( deg2rad(anglePoint) ) )* radius)
	#draw_polygon(pointsArc, colors)
	pass

func draw_line(start, end, color, existingDrawNode:Node = null, attach_to_world:bool = false):
	
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
		if attach_to_world:
			get_tree().get_root().add_child(draw_path_node)
		else:
			get_parent().add_child(draw_path_node)

	return draw_path_node