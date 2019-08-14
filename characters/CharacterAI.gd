extends Node

class_name CharacterAI

var me:Spatial = null
var awareness:Spatial = null

var find_nearest_waypoint_behind = false


###############
var chasing_for_attack:bool = false

func _ready():
	me = get_parent()
	if me.controlled_by_player:
		set_physics_process(false)
		return
		
	get_parent().get_node("AnimationTree")["parameters/Locomotion/blend_position"] = 0
	#$AnimationTree["parameters/Locomotion/blend_position"] = 1

	awareness = get_parent().get_node('Awareness')

var on_alert:bool = false
var sweep_for_player_in_range:bool = false
func _physics_process(delta):
	
	if me.path_fail:
		print('Path Failure')
		me.process_movement = false
		return
	
	me.echo('My hostility level is : ' + str(me.hostility_level) )
	if me.hostility_level == me.HOSTILITY_LEVELS.HUNTER:
		if awareness.i_can_see_the_character:
			if not chasing_for_attack or not me.is_moving():
				me.echo('attacking this guy..')
				me.set_navigation_path(awareness.target_character.transform.origin)
				me.set_travel_speed(1.3)
				me.process_movement = true
				chasing_for_attack = true
		
		# Character is here somewhere...
		if not awareness.i_can_see_the_character and chasing_for_attack and awareness.target_character:
			me.echo('This character must be behind me, around my field of vision..')
			sweep_for_player_in_range = true
			
		if sweep_for_player_in_range and not awareness.target_character:
			me.echo('This character is far, so I must be on alert...')
			on_alert = true
			sweep_for_player_in_range = false
			
	
	if me.patrol_waypoints and not awareness.i_can_see_the_character and not sweep_for_player_in_range:
		chasing_for_attack = false
		
		if me.navigation_path.empty():
			var waypoint = grab_random_waypoint()
	
			if not waypoint:
				me.process_movement = false
				return
			
			if me.set_navigation_path( waypoint.get_translation() ):
				me.set_travel_speed(1.0)
				me.process_movement = true
			else:
				me.process_movement = false
				return
				# Try again, otherwise, just idle this pawn.
	
			me.remaining_access_time = me.DESTINATION_ACCESS_TIME



func ____physics_process(delta):

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
				
		me.echo('Could Not reach destination in time.. Teleporting: ', me.teleport_on_fail)

	me.remaining_access_time -= delta

	# Is our character stuck?
	me.time_distance_moved += delta

	if me.time_distance_moved >= me.INTERVAL_TO_CHECK_DISTANCE_MOVED: #If one second has elapsed
		var total_position = me.transform.origin - me.beginning_position # Generate a Vector difference between the two.
		if total_position.length() < me.CHARACTER_STUCK_DEADZONE: # The character might be stuck.

			# Find nearest waypoint behind the character.
			find_nearest_waypoint_behind = true

			#get_navigation_path( grab_random_waypoint() )

		me.beginning_position = me.transform.origin # Record this beginning position
		me.time_distance_moved = 0

func grab_random_waypoint():
	if me.waypoints.empty():
		return false

	var waypoint = me.waypoints[ int( round( rand_range( 0, me.waypoints.size() - 1 ) ) ) ].get_name(1)
	#find_node is slow...may remove later
	#print(me.waypoints[ int( round( rand_range( 0, me.waypoints.size() - 1 ) ) ) ].get_name(1))
	return get_tree().get_root().find_node(waypoint, true, false) 