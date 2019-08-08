
extends Navigation

# Member variables
const SPEED = 4.0

var camrot = 0.0

var begin = Vector3()
var end = Vector3()
var m = SpatialMaterial.new()

var path = []
var draw_path = true

const ROTATION_SPEED = 1

func _process(delta):

	return

	if (path.size() > 1):
		var to_walk = delta*SPEED
		var to_watch = Vector3(0, 1, 0)
		while(to_walk > 0 and path.size() >= 2):
			var pfrom = path[path.size() - 1]
			var pto = path[path.size() - 2]
			to_watch = (pto - pfrom).normalized()
			var d = pfrom.distance_to(pto)
			if (d <= to_walk):
				path.remove(path.size() - 1)
				to_walk -= d
			else:
				path[path.size() - 1] = pfrom.linear_interpolate(pto, to_walk/d)
				to_walk = 0

		var atpos = path[path.size() - 1]
		var atdir = to_watch
		atdir.y = 0

		var t = Transform()
		t.origin = atpos
		t=t.looking_at(atpos + atdir, Vector3(0, 1, 0))
		get_node("Robot").set_transform(t)

		if (path.size() < 2):
			path = []
			set_process(false)
	else:
		set_process(false)


func _update_path():
	var p = get_simple_path(begin, end, true)
	path = Array(p) # Vector3array too complex to use, convert to regular array
	#path.invert()

	if path.size() and not path.empty():
		for i in range(0, path.size() ):
			#path[i].y = 0
			pass

		$SimpleMan.set_paths(path)
	#set_process(true)

	if (draw_path):
		var im = get_node("Draw")
		im.set_material_override(m)
		im.clear()
		im.begin(Mesh.PRIMITIVE_POINTS, null)
		
		im.add_vertex(Vector3(begin.x, begin.y, begin.z ) )
		im.add_vertex(Vector3(end.x, end.y, end.z ) )
		im.end()
		im.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
		for x in p:
			im.add_vertex(x)
		im.end()


func _input(event):
#	if (event extends InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed):
	if (event.is_class("InputEventMouseButton") and event.button_index == BUTTON_LEFT and event.pressed):
		var from = get_node("Camera").project_ray_origin(event.position)
		var to = from + get_node("Camera").project_ray_normal(event.position)*100
		var p = get_closest_point_to_segment(from, to)

		begin = get_closest_point(get_node("SimpleMan").get_translation())
		end = p

		_update_path()

var character_queues = []

func generate_path(requester, destination):
	print( requester.get_instance_id() )
	
	var start_path = get_closest_point(requester.get_translation())
	var end_path = get_closest_point(destination.get_translation())
	var p = get_simple_path(start_path, end_path, true)
	var found_queue

	
	for i in range(0, character_queues.size()):
		if character_queues[i].name == requester.get_instance_id():
			found_queue = i
			break
			
	var dictionary_form = {
		'name' : requester.get_instance_id(),
		'begin' : start_path,
		'end' : end_path,
		'paths' : Array(p)
	}
		
	if found_queue:
		character_queues[found_queue] = dictionary_form
	else:
		character_queues.append(dictionary_form)
	
	return Array(p)
	
	pass

func _ready():
	set_process_input(true)

	m.flags_unshaded = true
	m.flags_use_point_size = true
	m.albedo_color = Color(1.0, 1.0, 1.0, 1.0)