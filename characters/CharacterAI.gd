extends Character

class_name AI

export(Array, NodePath) var waypoints

func _ready():
	$AnimationTree["parameters/Locomotion/blend_position"] = 0
	#$AnimationTree["parameters/Locomotion/blend_position"] = 1

func _physics_process(delta):

	if path_fail:
		print('Path Failure')
		process_movement = false
		return


	if navigation_path.empty():
		var waypoint = grab_random_waypoint()

		if not waypoint:
			process_movement = false
			return
		
		if not get_navigation_path( waypoint.get_translation() ):
			process_movement = false
			return
			# Try again, otherwise, just idle this pawn.


		remaining_access_time = DESTINATION_ACCESS_TIME

	# Is our character unable to reach their destination in time?
	if remaining_access_time <= 0:
		remaining_access_time = DESTINATION_ACCESS_TIME

		if teleport_on_fail:
			global_transform.origin = navigation_path[navigation_path.size()-1]
			navigation_path = []
		else:
			var waypoint = grab_random_waypoint()
			if not waypoint:
				process_movement = false
				return

			if not get_navigation_path( waypoint.get_translation() ):
				process_movement = false
				return

		print('Could Not reach destination in time.. Teleporting: ', teleport_on_fail)

	remaining_access_time -= delta

	# Is our character stuck?
	time_distance_moved += delta

	if time_distance_moved >= INTERVAL_TO_CHECK_DISTANCE_MOVED: #If one second has elapsed
		var total_position = transform.origin - beginning_position # Generate a Vector difference between the two.
		if total_position.length() < CHARACTER_STUCK_DEADZONE: # The character might be stuck.

			# Find nearest waypoint behind the character.
			find_nearest_waypoint_behind = true

			#get_navigation_path( grab_random_waypoint() )

		beginning_position = transform.origin # Record this beginning position
		time_distance_moved = 0

func grab_random_waypoint():
	if waypoints.empty():
		return false

	var waypoint
	#find_node is slow...may remove later
	waypoint = get_node( waypoints[ int( round( rand_range( 0, waypoints.size() - 1 ) ) ) ])
	return waypoint