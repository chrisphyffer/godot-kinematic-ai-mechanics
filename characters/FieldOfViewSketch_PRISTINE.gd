extends Spatial

var local_forward:Vector3 = Vector3()
var global_forward:Vector3 = Vector3()

var line_collection:Array = []

var target_character:Node
const ROTATION_SPEED = .3
#const ROTATION_DELAY_PERIOD = .1 # If other characters are super fast and this one can't catch up.
var rotation_delayed = 0
var done_rotating:bool
var accum_rotation = 0.0

var positionsOfInterest = {
	'lastSeenPosition': false, # Position of player last seen
	'lastLostPosition': false, # Position of enemy when player lost
	'outsideRange': false
	}

var initial_forward = Vector3()

export var field_of_view = 45
export var field_of_view_resolution = 3
export var field_of_view_ray_length = 20
var field_of_view_draws = []
var field_of_view_array_filled = false
var fov_height = 1



const QUAT_EQUIVALENCE_DEADZONE:float = .15
var looked_around_for_character = false
var look_around_rotation = false
var bodies_in_awareness = []
var go_reverse = false


func _ready():
	# FORWARD transform.basis.z
	line_collection = [
		{'color': Color(1,0,0,1), 'end' : transform.origin + Vector3(3,0,5), 'start' : transform.origin },
		{'color': Color(1,1,0,1), 'end' : (global_transform.origin + Vector3(0,0,5) ) , 'start' : global_transform.origin }
	]

	for i in range(0, line_collection.size()):
		draw_line(line_collection[i].start, line_collection[i].end, line_collection[i].color)

	$RayCast.exclude_parent = true
	$RayCast.add_exception(self)
	for child in get_parent().get_children():
		print(get_parent().name, ' - > ' , child.name)
		$RayCast.add_exception(child)

	print('PARENT: ', get_parent())

	initial_forward = get_parent().transform.basis.z
	field_of_view_resolution = float(field_of_view_resolution)
	return
	


func draw_field_of_view():
	var parent = get_parent().transform

	var origin_pos = Vector3(parent.origin.x, fov_height, parent.origin.z)
	
	
	var current_angle = deg2rad(0)
	
	#draw_line(origin_pos, destVector, Color(0,1,0,1) )
	#print(forward)
	#print(destVector)

	var start_angle = - ( field_of_view *.5 )
	var space_state = get_world().direct_space_state
	var finalDestination
	
	for i in range( ( field_of_view+1 ) * field_of_view_resolution):
		
		var forward = initial_forward * field_of_view_ray_length
		
		current_angle = deg2rad( start_angle + ( i / field_of_view_resolution )   )
		#print('CURRENTANGLE',  start_angle + ( i / field_of_view_resolution ) )
		var field_of_view_ray_color = Color(1,1,1,1)
		
		var destVector = Vector3()
		destVector.x = ( forward.x * cos(current_angle) ) - ( forward.z * sin(current_angle) )
		destVector.y = fov_height
		destVector.z = ( forward.x * sin(current_angle) ) + ( forward.z * cos(current_angle) )

		var result = space_state.intersect_ray( parent.origin, to_global(destVector) )
		
		if (i/field_of_view_resolution) == ceil(field_of_view / 2):
			#print('STANDARD: ', finalDestination)
			field_of_view_ray_color = Color(1,0,0,1)
			
		if not result.empty():
			#print('ray_hit', i)
			var result_l = to_local(result.position)
			finalDestination = result_l
			#finalDestination = destVector
			#if i == ceil(field_of_view / 2):
				#print('COLLIER: ', finalDestination, ' NAME: ', result.collider.name)
		else:
			finalDestination = destVector

		if rad2deg(current_angle*2) != field_of_view:
			pass # Change Color

		if field_of_view_array_filled:
			draw_line(origin_pos, finalDestination, field_of_view_ray_color, \
					field_of_view_draws[i])
		else:
			field_of_view_draws.append( draw_line(origin_pos, finalDestination, \
				 field_of_view_ray_color) )

		#if i == 0:
		#	start_vector = destVector
		#elif i == field_of_view:
		#	end_vector = destVector

		#var angle_reversed = rad2deg( acos(forwarded.normalized().dot(destVector.normalized())) )

		if(int( float(i) / field_of_view_resolution ) % 10 == 0 and not field_of_view_array_filled):
			var angle_reversed = rad2deg( acos( (initial_forward * field_of_view_ray_length).normalized().dot( destVector.normalized() ) ) )
			#print(' ANGLE : ', rad2deg(current_angle), origin_pos, destVector, \
			#' DOT : ', (initial_forward * field_of_view_ray_length).normalized().dot(destVector.normalized()), ' Reversed Angle: ', angle_reversed)

	field_of_view_array_filled = true


func _physics_process(delta):
	var parent = get_parent().transform

	draw_field_of_view()

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
		target_character = find_nearest_character(parent)


	if target_character:
		# ROTATION IS BACKWARDS -Z IN GODOT....
		var inverted_character_position = Vector3(-target_character.transform.origin.x, parent.origin.y, -target_character.transform.origin.z)
		var target_rotation = false
		var currentRotation = false
		var characterInSight = false

		$RayCast.look_at(inverted_character_position, Vector3(0,1,0))
		$RayCast.force_raycast_update()
		if $RayCast.is_colliding():
			var body = $RayCast.get_collider()
			if body.is_in_group('Character'):

				if character_in_view(target_character.transform.origin, parent.origin, parent.basis.z):
					target_rotation = parent.looking_at(inverted_character_position, Vector3(0,1,0))
					currentRotation = Quat(parent.basis).slerp(target_rotation.basis, delta * ROTATION_SPEED)
					positionsOfInterest.lastSeenPosition = inverted_character_position
					pursue_character(currentRotation, parent.origin)
					look_around_rotation = false
					characterInSight = true
					#print('Character is in view')
				elif not looked_around_for_character:
					# Look around wildly for character, maybe he is behind you!
					#looked_around_for_character = look_around_for_character(delta, parent, PI)

					pass

				pass
			else:
				# Character is behind something.
				positionsOfInterest.lastLostPosition = positionsOfInterest.lastSeenPosition

				target_rotation = parent.looking_at(positionsOfInterest.lastLostPosition, Vector3(0,1,0))
				currentRotation = Quat(parent.basis).slerp(target_rotation.basis, delta * ROTATION_SPEED)
				pursue_character(currentRotation, parent.origin)

				#print('Character Last Seen: ', positionsOfInterest.lastLostPosition)

			# WHERE WAS THE TARGET LAST SEEN???!?! GO THERE.
			# If lost body....then target_character == ?!
			# Depending on agression, hunt character or just find the other target.
			#print(body.name)
		#else:
		#	print('nocolission..')
			#if body.has_method("bullet_hit"):
				#body.bullet_hit(TURRET_DAMAGE_RAYCAST, $RayCast.get_collision_point())

		if characterInSight == false:
			if character_is_audible():
				# Pay Attention, he's around here somewhere...
				pass


func find_nearest_character(parent:Transform):
	var shortest_body = null
	var shortest_distance = false
	for i in range(0, bodies_in_awareness.size()):

		# Who is in our field of vision?
		if not character_in_view(bodies_in_awareness[i].transform.origin, parent.origin, parent.basis.z):
			continue

		# Which body is closer?
		var distance = parent.origin.distance_to(bodies_in_awareness[i].transform.origin)

		if not shortest_body:
			shortest_body = bodies_in_awareness[i]

		if parent.origin.distance_to(bodies_in_awareness[i].transform.origin) < parent.origin.distance_to(shortest_body.transform.origin):
			shortest_distance = distance
			shortest_body = bodies_in_awareness[i]

	return shortest_body

func character_in_view(characterPosition:Vector3, currentPosition:Vector3, forwardVector:Vector3):

	var pa = (characterPosition - currentPosition).normalized()
	
	# I want the character's origin, not his capsule, this is why
	# This character in view will detect only the players origin, not a ray hitting a capsule...
	
	if rad2deg( acos( pa.dot(forwardVector) ) ) <= field_of_view/2:
		return true
		
	return false

# Footsteps
func character_is_audible():
	pass


func pursue_character(currentRotation:Quat, currentPosition:Vector3):
	get_parent().set_transform( Transform(currentRotation, currentPosition).orthonormalized() )
	pass



func quat_roughly_equal_to(quat1:Quat, quat2:Quat):

	if quat1.y - QUAT_EQUIVALENCE_DEADZONE < quat2.y and\
		quat1.y + QUAT_EQUIVALENCE_DEADZONE > quat2.y and\
		quat1.w - QUAT_EQUIVALENCE_DEADZONE < quat2.w and\
		quat1.w + QUAT_EQUIVALENCE_DEADZONE > quat2.w:
		return true

	return false


func look_around_for_character(delta:float, parent:Transform, targetAngle:float=PI):
	if not look_around_rotation:
		look_around_rotation = parent.rotated(Vector3(0,1,0), targetAngle)

	if quat_roughly_equal_to(get_parent().transform.basis.get_rotation_quat(), look_around_rotation.basis.get_rotation_quat()):
		print('Quat match')
		return true

	var targetRotation = Quat(parent.basis).slerp(look_around_rotation.basis, delta * ROTATION_SPEED)
	pursue_character(targetRotation, parent.origin)


func _entered_field_of_awareness(body:Node):

	if body.is_in_group('Character'):
		bodies_in_awareness.append(body)
		print(body)

	pass # Replace with function body.


func _exited_field_of_awareness(body):

	if target_character == body:
		target_character = null

	var index = bodies_in_awareness.find(body)
	if index != -1:
		bodies_in_awareness.remove(index)
	print(body, ' => ', index)
	pass # Replace with function body.


func back_forth_rotate(delta):

	var parent = get_parent().transform
	var look_to # Normalized Vector, just gives us a direction.
	var incrementer = delta * ROTATION_SPEED

	if go_reverse:
		look_to = Vector3(1,0,0)
	else:
		look_to = Vector3(-1,0,0)

	var edge = parent.looking_at(parent.origin + look_to, Vector3(0,1,0))
	var rotated = Quat(parent.basis.orthonormalized()).slerp(edge.basis, clamp(accum_rotation, 0, 1))
	#var something= parent.origin.cross(parent.origin+look_to)
	#var something2 = Vector2(parent.origin.x, parent.origin.z).dot(Vector2(1,0))

	get_parent().transform.basis = Transform(rotated, parent.origin).basis

	accum_rotation += incrementer
	if accum_rotation >= 1:
		accum_rotation = 0
		go_reverse = !go_reverse



	
	
	
	

	if not existingDrawNode:
		get_parent().add_child(draw_path_node)

	return draw_path_node
