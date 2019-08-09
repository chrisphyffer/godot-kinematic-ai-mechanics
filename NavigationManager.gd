extends Navigation

func generate_path(requester : Node, destination : Vector3):

	var start_path = get_closest_point(requester.get_translation())
	var end_path = get_closest_point(destination)
	var p = get_simple_path(start_path, end_path, true)
	var paths = Array(p)

	return paths