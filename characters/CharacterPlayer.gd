extends Character

class_name Player

var camera : Camera = null

export var point_and_click : bool = true

func _ready():
	if point_and_click == true:
		camera = get_tree().get_root().find_node('Camera', true, false)

func _input(event):
	
	# Point and Click Adventure!
	
#	if (event extends InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed):
	if (event.is_class("InputEventMouseButton") and event.button_index == BUTTON_LEFT and event.pressed):
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position)*100
		var end = navLevel.get_closest_point_to_segment(from, to)
		
		var _paths = get_navigation_path( end )
		if typeof(_paths) == TYPE_ARRAY:
			navigation_path = _paths
		else:
			print('Cannot Generate Paths from Input')
			
func _physics_process(delta):
	pass