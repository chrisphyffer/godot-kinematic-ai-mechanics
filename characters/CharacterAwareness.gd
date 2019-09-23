extends Spatial
class_name CharacterAwareness

var me = null

#######################
# Direction
var initial_forward = Vector3()


#######################
# Field Of View
var field_of_view_array_filled = false


#######################
# Entity Detection
var target_character:Node #Determines if the character is in range of awareness. (NEARBY TARGET)
var positionsOfInterest = {
	'lastSeenPosition': false, # Position of player last seen
	'lastLostPosition': false, # Position of enemy when player lost
	'outsideRange': false
	}
var bodies_in_awareness = []
var i_can_see_the_character:bool = false


#######################
# Debug Assistance
var field_of_view_draws = []
var debug_node:Node = null

func _ready():

	# Grab our initial Forward Vector
	#initial_forward = get_tree().get_root().get_node( get_parent().get_path() ).transform.basis.z # GET THE REAL PARENTS TRANSFORM BASIS!!!! NOT THE ONE WITHIN THE WITHIN..
	initial_forward = Vector3(0,0,1)
	me = get_parent()
	debug_node = get_parent().get_node('Debug')
		
	var shap = $Area/CollisionShape.get_shape()
	shap.set_radius(me.radius_of_awareness)
	
	if me.debug_mode:
		print('RADIUS OF AWARENESS :: ', shap.get_radius())

var rayNode = null
var debug_draws_complete = false

func _physics_process(delta):
	var parent = me.transform
	i_can_see_the_character = false

	if me.debug_mode and not debug_draws_complete:
		var line_collection = [
			{'rayNode': null, 'color': Color(1,0,0,1), 'end' : me.transform.origin + Vector3(0, me.fov_height+1, 15), 'start' : me.transform.origin+Vector3(0,me.fov_height,0) },
			{'rayNode': null, 'color': Color(1,1,0,1), 'end' : me.global_transform.origin + Vector3(0 ,me.fov_height+1, 15) , 'start' : me.global_transform.origin+Vector3(0,me.fov_height,0) }
		]
		
		for i in range(0, line_collection.size()):
			if me.debug_mode:
				line_collection[i].rayNode = debug_node.draw_line(line_collection[i].start,\
				 line_collection[i].end, line_collection[i].color, \
				line_collection[i].rayNode) 
					
		debug_node.draw_circle_arc(Vector3(0, me.fov_height, 0), \
			me.radius_of_awareness, Color(1,1,0,1))
			
		debug_node.draw_circle_arc(Vector3(0, me.fov_height, 0), \
			me.vision_max_distance, Color(0,0,0,1))
		
		debug_draws_complete = true

	if me.debug_mode:
		draw_field_of_view()
		pass

	if bodies_in_awareness.empty():
		return

	#if target_character:
	#
	#	# I lost sight of the character, but I can still hear them! Panic and quickly turn around
	#	# to some random direction to see if they are there.
	#	# If body is too far, (Least audible distance, then just be on alert)

	#	var pa = (target_character.transform.origin - parent.origin).normalized()
	#	if pa.dot(parent.basis.z) < 0:
	#		target_character
	#
	#	print(pa.dot(parent.basis.z))

	if not target_character:
		me.echo('I have no target Characters.. Looking for other characters..')
		i_can_see_the_character = false
		target_character = find_nearest_character()
		
	if target_character:
		

		# REVERSE THE LOOKAT POSITION....
		var target_height = target_character.character_height / 2
		var char_pos = target_character.transform.origin
		char_pos.y = char_pos.y + target_height
		
		var parent_transform = parent.origin + Vector3(0,target_height,0)
		#me.echo('I have a target character ('+target_character.name+ str(target_character.transform.origin) + '), checking if they are on my field of view.')
		
		# ROTATION IS BACKWARDS -Z IN GODOT....
		
		var target_rotation = false
		var currentRotation = false
		var characterInSight = false
		
		# Since our character is facing -z...
		var forward_vector = -get_parent().transform.basis.z
		
		var space_state = get_tree().get_root().get_world().direct_space_state
		var result = space_state.intersect_ray( parent_transform, char_pos )
		
		if me.debug_mode:
			rayNode = debug_node.draw_line(parent_transform, char_pos,\
				 Color(1,1,1,1), rayNode, true)
		
		if not result.empty():
			
			var body = result.collider
			me.echo('RAYCAST COLLIDING: ('+body.name+')')
				
			if body.is_in_group('Character'):
				
				me.echo('Target Character('+body.name+') is in the *Character Group*, and nothing'+\
					' is obstructing my vision of them.')
					
				if character_in_view(char_pos, parent_transform, forward_vector):
					me.echo('I can see this character')
					i_can_see_the_character = true
					#~~target_rotation = parent.looking_at(inverted_character_position, Vector3(0,1,0))
					#~~currentRotation = Quat(parent.basis).slerp(target_rotation.basis, delta * ROTATION_SPEED)
					#~~positionsOfInterest.lastSeenPosition = inverted_character_position
					#~~pursue_character(currentRotation, parent.origin)
					#~~look_around_rotation = false
					#~~characterInSight = true
				else:
					me.echo('I cannot see this character, Character is out of my FOV: ')
					#print('Character is in view')
				pass
			else:
				pass
				# Character is behind something.
				#~~positionsOfInterest.lastLostPosition = positionsOfInterest.lastSeenPosition

				#~~target_rotation = parent.looking_at(positionsOfInterest.lastLostPosition, Vector3(0,1,0))
				#~~currentRotation = Quat(parent.basis).slerp(target_rotation.basis, delta * ROTATION_SPEED)
				#~~pursue_character(currentRotation, parent.origin)

				#print('Character Last Seen: ', positionsOfInterest.lastLostPosition)

			# WHERE WAS THE TARGET LAST SEEN???!?! GO THERE.
			# If lost body....then target_character == ?!
			# Depending on agression, hunt character or just find the other target.
			#print(body.name)
		#else:
		#	print('nocolission..')
			#if body.has_method("bullet_hit"):
				#body.bullet_hit(TURRET_DAMAGE_RAYCAST, $RayCast.get_collision_point())

		if i_can_see_the_character == false:
			if character_is_audible():
				# Pay Attention, he's around here somewhere...
				pass
				



#############################
# find_nearest_character()
# Finds the nearest character to this character.

func find_nearest_character():
	
	var forward_vector = -get_parent().transform.basis.z
	
	var parent = me.transform
	var shortest_body = null
	var shortest_distance = false
	for i in range(0, bodies_in_awareness.size()):
		# Who is in our field of vision?
		
		var target_height = bodies_in_awareness[i].character_height / 2
		var char_pos = bodies_in_awareness[i].transform.origin
		char_pos.y = char_pos.y + target_height
		var parent_transform = parent.origin + Vector3(0,target_height,0)
		
		if not character_in_view(char_pos, parent_transform, forward_vector):
			continue
		
		# Which body is closer?
		var distance = parent.origin.distance_to(bodies_in_awareness[i].transform.origin)

		if not shortest_body:
			shortest_body = bodies_in_awareness[i]

		if parent.origin.distance_to(bodies_in_awareness[i].transform.origin) < parent.origin.distance_to(shortest_body.transform.origin):
			shortest_distance = distance
			shortest_body = bodies_in_awareness[i]
	
	return shortest_body

#############################
# character_in_view()
# Is this character in my field of view?

func character_in_view(characterPosition:Vector3, currentPosition:Vector3, forwardVector:Vector3):
	
	var pa = (characterPosition - currentPosition).normalized()
	
	#me.echo(str(characterPosition) +  ' <   > ' + str(currentPosition) + ' &&& ' + str(forwardVector)  +' ~~~~~~ ' + str(rad2deg( acos( pa.dot(forwardVector) ) ) ) )
		
	# I want the character's origin, not his capsule, this is why
	# This character in view will detect only the players origin, not a ray hitting a capsule...
	if rad2deg( acos( pa.dot(forwardVector) ) ) <= me.field_of_view/2:
		return true
		
	return false


#############################
# find_nearest_character()
# Determines if the Character is Audible

func character_is_audible():
	pass




# ############################# START : NODE SIGNALS
#

func _entered_field_of_awareness(body:Node):
	if body.is_in_group('Character'):
		#print('CHARACTER', body)
		#print('WHO ME?', get_parent())
		if me.debug_mode:
			print(body.name, ' --- ', get_parent().name)
		if body.name != get_parent().name:
			if me.debug_mode:
				print(body.name)
				print(body.transform.origin)
			bodies_in_awareness.append(body)
		#print(body)


func _exited_field_of_awareness(body):

	if target_character == body:
		target_character = null

	var index = bodies_in_awareness.find(body)
	if index != -1:
		bodies_in_awareness.remove(index)
	#print(body, ' => ', index)

#
# ############################# END : NODE SIGNALS




#############################
# draw_field_of_view()
# Draws a set of lines across the specified field of view to
# represent the character's field of view.

func draw_field_of_view():

	var parent = me.get_transform()

	#var origin_pos = Vector3(parent.origin.x, me.fov_height, parent.origin.z)
	var origin_pos = Vector3(0, me.fov_height, 0)

	var start_angle = - ( me.field_of_view *.5 )
	var space_state = get_world().direct_space_state
	var finalDestination
	var current_angle = 0

	for i in range( ( me.field_of_view+1 ) * me.field_of_view_resolution):

		var forward = initial_forward * me.vision_max_distance

		current_angle = deg2rad( start_angle + ( i / me.field_of_view_resolution )   )
		#print('CURRENTANGLE',  start_angle + ( i / field_of_view_resolution ) )
		var field_of_view_ray_color = Color(1,1,1,1)

		var destVector = Vector3()
		destVector.x = ( forward.x * cos(current_angle) ) - ( forward.z * sin(current_angle) )
		destVector.y = me.fov_height
		destVector.z = -1 *  ( ( forward.x * sin(current_angle) ) + ( forward.z * cos(current_angle) ) )

		var result = space_state.intersect_ray( parent.origin, to_global(destVector) )

		if (i/me.field_of_view_resolution) == ceil(me.field_of_view / 2):
			#print('STANDARD: ', finalDestination)
			field_of_view_ray_color = Color(1,0,0,1)

		if not result.empty():
			#print('ray_hit', i)
			var result_l = to_local(result.position)
			result_l.y = me.fov_height
			finalDestination = result_l
			#finalDestination = destVector
			#if i == ceil(field_of_view / 2):
				#print('COLLIER: ', finalDestination, ' NAME: ', result.collider.name)
		else:
			finalDestination = destVector

		if rad2deg(current_angle*2) != me.field_of_view:
			pass # Change Color

		if field_of_view_array_filled:
			debug_node.draw_line(origin_pos, finalDestination, field_of_view_ray_color, \
					field_of_view_draws[i])
		else:
			field_of_view_draws.append( debug_node.draw_line(origin_pos, finalDestination, \
				 field_of_view_ray_color) )

		#if i == 0:
		#	start_vector = destVector
		#elif i == field_of_view:
		#	end_vector = destVector

		#var angle_reversed = rad2deg( acos(forwarded.normalized().dot(destVector.normalized())) )

		if(int( float(i) / me.field_of_view_resolution ) % 10 == 0 and not field_of_view_array_filled):
			var angle_reversed = rad2deg( acos( (initial_forward * me.vision_max_distance).normalized().dot( destVector.normalized() ) ) )
			#print(' ANGLE : ', rad2deg(current_angle), origin_pos, destVector, \
			#' DOT : ', (initial_forward * me.vision_max_distance).normalized().dot(destVector.normalized()), ' Reversed Angle: ', angle_reversed)

	field_of_view_array_filled = true