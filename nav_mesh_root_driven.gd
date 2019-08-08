
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

	var angle

	if path.size() > 1:
		#get_node("Robot").rotate_y(angle)

		var atpos = path[path.size() - 1]
		var desired_transform = get_node("Robot").transform.looking_at(atpos, Vector3(0,1,0))




		#set_rotation(Matrix3(smooth_rot).get_euler())

		print( desired_transform.basis.get_euler().y, " = ", get_node("Robot").transform.basis.get_euler().y )

		path = []
		set_process(false)

		pass









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
	path.invert()

	if path.size() and not path.empty():
		$SimpleMan.set_paths(path)
	#set_process(true)


func _input(event):
#	if (event extends InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed):
	if (event.is_class("InputEventMouseButton") and event.button_index == BUTTON_LEFT and event.pressed):
		var from = get_node("Camera").project_ray_origin(event.position)
		var to = from + get_node("Camera").project_ray_normal(event.position)*100
		var p = get_closest_point_to_segment(from, to)

		begin = get_closest_point(get_node("Robot").get_translation())
		end = p

		_update_path()

func _ready():
	set_process_input(true)

	m.flags_unshaded = true
	m.flags_use_point_size = true
	m.albedo_color = Color(1.0, 1.0, 1.0, 1.0)