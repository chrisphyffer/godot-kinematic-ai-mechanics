
extends Navigation

# Member variables
const SPEED = 4.0

#var begin = Vector3()
#var end = Vector3()

#var path = []
#var draw_path = true

const ROTATION_SPEED = 1

var player = null

func _ready():
	
	player = get_tree().get_root().find_node('Player', true, false)
	if not player:
		get_tree().quit()

func _input(event):
#	if (event extends InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed):
	if (event.is_class("InputEventMouseButton") and event.button_index == BUTTON_LEFT and event.pressed):
		var from = get_node("Camera").project_ray_origin(event.position)
		var to = from + get_node("Camera").project_ray_normal(event.position)*100
		var end = get_closest_point_to_segment(from, to)
		
		var paths = generate_path(player, end)
		if typeof(paths) == TYPE_ARRAY:
			player.set_path(paths)

var character_queues = []

func update_character_queue(requester, start_path: Vector3, end_path: Vector3, paths: Array = [], draw_node: bool = false):

	var found_queue = null

	var dictionary_form = {
		'name' : requester.get_instance_id(),
		'begin' : start_path,
		'end' : end_path,
		'paths' : paths,
		'draw_node' : draw_node
	}
	
	for i in range(0, character_queues.size()):
		if character_queues[i].name == requester.get_instance_id():
			found_queue = i
			break
	
	if found_queue:
		dictionary_form.draw_node = character_queues[found_queue].draw_node
		character_queues[found_queue] = dictionary_form
	else:
		character_queues.append(dictionary_form)
		found_queue = character_queues.size()-1
		
	return found_queue
	

func generate_path(requester, destination : Vector3):
	
	var start_path = get_closest_point(requester.get_translation())
	var end_path = get_closest_point(destination)
	var p = get_simple_path(start_path, end_path, true)
	var paths = Array(p)
	
	if not paths:
		return
	
	var characterIndex = update_character_queue(requester, start_path, end_path, paths)
	
	if requester.draw_path:
		character_queues[characterIndex].draw_node = do_draw_path(characterIndex)
	
	if Array(p):
		return Array(p)
	else:
		return false
	
func path_completed(requester):
	var found_queue
	for i in range(0, character_queues.size()):
		if character_queues[i].name == requester.get_instance_id():
			found_queue = i
			break

	if found_queue != null:
		var drawNode = character_queues[found_queue]['draw_node']
		if drawNode:
			drawNode.queue_free()

func do_draw_path(characterIndex, player = false):
	
	var m = SpatialMaterial.new()
	m.albedo_color = Color(255, 255, 255, .5)
	m.flags_unshaded = true
	m.flags_use_point_size = true
	#m.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	
	var drawNode = false
	
	if not character_queues[characterIndex].draw_node:
		drawNode = ImmediateGeometry.new()
		add_child(drawNode)
	else:
		drawNode = character_queues[characterIndex].draw_node
		#print('drawing new node for character: ', character_queues[characterIndex].name)
	
	var paths = character_queues[characterIndex].paths
		
	
	drawNode.set_material_override(m)
	drawNode.clear()
	drawNode.begin(Mesh.PRIMITIVE_POINTS, null)
	
	drawNode.add_vertex(Vector3(paths[0].x, paths[0].y, paths[0].z ) )
	drawNode.add_vertex(Vector3(paths[paths.size()-1].x, paths[paths.size()-1].y, paths[paths.size()-1].z ) )
	drawNode.end()
	drawNode.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	for x in paths:
		drawNode.add_vertex(x)
	drawNode.end()

	return drawNode