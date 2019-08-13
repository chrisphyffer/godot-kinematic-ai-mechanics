extends Node

class_name CharacterAI

var me:Spatial = null

func _ready():
	
	me = get_parent()
	if me.controlled_by_player:
		set_physics_process(false)
		return
		
	
	get_parent().get_node("AnimationTree")["parameters/Locomotion/blend_position"] = 0
	#$AnimationTree["parameters/Locomotion/blend_position"] = 1

func _physics_process(delta):

	if me.path_fail:
		print('Path Failure')
		me.process_movement = false
		return


	if me.navigation_path.empty():
		var waypoint = grab_random_waypoint()

		if not waypoint:
			me.process_movement = false
			return
		
		if not me.get_navigation_path( waypoint.get_translation() ):
			me.process_movement = false
			return
			# Try again, otherwise, just idle this pawn.


		me.remaining_access_time = me.DESTINATION_ACCESS_TIME

	# Is our character unable to reach their destination in time?
	if me.remaining_access_time <= 0:
		me.remaining_access_time = me.DESTINATION_ACCESS_TIME

		if me.teleport_on_fail:
			me.global_transform.origin = me.navigation_path[me.navigation_path.size()-1]
			me.navigation_path = []
		else:
			var waypoint = grab_random_waypoint()
			if not waypoint:
				me.process_movement = false
				return

			if not me.get_navigation_path( waypoint.get_translation() ):
				me.process_movement = false
				return

		print('Could Not reach destination in time.. Teleporting: ', me.teleport_on_fail)

	me.remaining_access_time -= delta

	# Is our character stuck?
	me.time_distance_moved += delta

	if me.time_distance_moved >= me.INTERVAL_TO_CHECK_DISTANCE_MOVED: #If one second has elapsed
		var total_position = me.transform.origin - me.beginning_position # Generate a Vector difference between the two.
		if total_position.length() < me.CHARACTER_STUCK_DEADZONE: # The character might be stuck.

			# Find nearest waypoint behind the character.
			me.find_nearest_waypoint_behind = true

			#get_navigation_path( grab_random_waypoint() )

		me.beginning_position = me.transform.origin # Record this beginning position
		me.time_distance_moved = 0

func grab_random_waypoint():
	if me.waypoints.empty():
		return false

	var waypoint
	#find_node is slow...may remove later
	waypoint = get_node( me.waypoints[ int( round( rand_range( 0, me.waypoints.size() - 1 ) ) ) ])
	return waypoint