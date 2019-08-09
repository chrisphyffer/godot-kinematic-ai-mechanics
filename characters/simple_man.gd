extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

class_name Character

var paths = []
var accumulated_rotation = 0
var arrived_at_position = false
var rotated_to_position = false
var orientation = Transform()
var velocity = Vector3()
const GRAVITY = Vector3(0,-9.8, 0)

export var is_ai = false

export(Material) var body_material setget set_body_material

export(Array, NodePath) var waypoints

var navLevel

export(bool) var draw_path = true
export(bool) var teleport_on_fail = false

const PATH_FAIL_MAX = 3
var path_fail = 0
const MAX_ERRORS = 10
var errors = 0

const INTERVAL_TO_CHECK_DISTANCE_MOVED = 1
var time_distance_moved = 0
var beginning_position = Vector3()
var CHARACTER_STUCK_DEADZONE = .2


# If I cannot access my destination time (whether there is someone in the way or
# I simply cannot get there...then teleport me there.
const DESTINATION_ACCESS_TIME = 6000
var remaining_access_time = DESTINATION_ACCESS_TIME

# Called when the node enters the scene tree for the first time.
func _ready():
	orientation=global_transform
	orientation.origin = Vector3()
	navLevel = get_tree().get_root().find_node('Level', true, false)

	if is_ai:
		$AnimationTree["parameters/Locomotion/blend_position"] = 2
		#$AnimationTree["parameters/Locomotion/blend_position"] = 1

func set_body_material(mat: Material):
	find_node('SimpleManMesh').set_surface_material(0, mat)


func _process_movement(delta):

	if typeof(paths) != TYPE_ARRAY:
		$AnimationTree["parameters/Locomotion/blend_position"] = 0
		return

	if paths.empty():
		$AnimationTree["parameters/Locomotion/blend_position"] = 0
		return

	if global_transform.origin.distance_to(paths[0]) < .5:
		accumulated_rotation = 0
		paths.remove(0)

		if paths.empty():
			return

	var t = transform
	paths[0].y = t.origin.y

	var rotTransform = t.looking_at(paths[0], Vector3(0,1,0))
	var thisRotation = Quat(t.basis).slerp( rotTransform.basis, clamp(accumulated_rotation, 0, 1) )

	accumulated_rotation += delta

	if accumulated_rotation > 1:
		accumulated_rotation = 1

	if not rotated_to_position:
		orientation.basis = Transform(thisRotation, t.origin).basis

	$AnimationTree["parameters/Locomotion/blend_position"] = 2
	$AnimationTree["parameters/LocomotionTimeScale/scale"] = 1

	var root_motion = $AnimationTree.get_root_motion_transform()

	# apply root motion to orientation
	orientation *= root_motion

	var h_velocity = orientation.origin / delta
	velocity.x = -h_velocity.x # NEGATIVES DUE TO FLIPPED Z FRONT...
	velocity.z = -h_velocity.z # NEGATIVES DUE TO FLIPPED Z FRONT...
	velocity += GRAVITY * delta
	velocity = move_and_slide(velocity, Vector3(0,1,0))

	orientation.origin = Vector3() #clear accumulated root motion displacement (was applied to speed)
	orientation = orientation.orthonormalized() # orthonormalize orientation

	global_transform.basis = orientation.basis

	pass



func _physics_process(delta):

	if is_ai and path_fail:
		return

	if is_ai:
		if paths.empty():
			if not generate_paths(grab_random_waypoint()):
				return
				# Try again, otherwise, just idle this pawn.

			remaining_access_time = DESTINATION_ACCESS_TIME

		# Is our character unable to reach their destination in time?
		if remaining_access_time <= 0:
			remaining_access_time = DESTINATION_ACCESS_TIME

			if teleport_on_fail:
				global_transform.origin = paths[paths.size()-1]
				paths = []
			else:
				if not generate_paths(grab_random_waypoint()):
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

				#generate_paths(grab_random_waypoint())

			beginning_position = transform.origin # Record this beginning position
			time_distance_moved = 0

	_process_movement(delta)
	_check_vision(delta)

func grab_random_waypoint():
	var waypoint
	while not waypoint:
		waypoint = get_tree().get_root().find_node( waypoints[ int( round( rand_range( 0, waypoints.size() - 1 ) ) ) ], true, false )
		errors += 1

	return waypoint

func generate_paths(waypoint: Node):
	paths = navLevel.generate_path(self, waypoint.get_translation())
	if paths and not paths.empty():
		return true

	path_fail = true
	print('Path Fail')
	return false

# Player Only
func set_path(paths_arg: Array):
	accumulated_rotation = 0
	paths = paths_arg
	arrived_at_position = false
	rotated_to_position = false
	$AnimationTree["parameters/Locomotion/blend_position"] = 1


var find_nearest_waypoint_behind = false

##################
# CHECK VISION
func _check_vision(delta):
	#Scan for waypoints behind this character.
	if find_nearest_waypoint_behind:
		#print('Character stuck, finding nearest waypoint away from my facing direction')
		$AreaOfAwareness.monitoring = true
		for i in range(0, bodies_in_awareness.size()-1):
			if bodies_in_awareness[i].get_owner().is_in_group('Waypoint'):
				var target_waypoint = bodies_in_awareness[i]
				navLevel.generate_path(self, target_waypoint)
				find_nearest_waypoint_behind = false
				$AreaOfAwareness.monitoring = false
				#print('YAS')

				#var AP = (target_waypoint.get_transform().origin - transform.origin).normalized()
				#if AP.dot(transform.basis.x) >= 0:
				#	print('SEEING WAYPOINT.')
				#	navLevel.generate_path(self, target_waypoint)
				#	find_nearest_waypoint_behind = false
				#	break
		
		if find_nearest_waypoint_behind:
			generate_paths(grab_random_waypoint())
			find_nearest_waypoint_behind = false
			$AreaOfAwareness.monitoring = false

	pass

var bodies_in_awareness = []
func _object_entered_area_of_awareness(body):
	bodies_in_awareness.append(body)
	pass

func _object_exited_area_of_awareness(body):
	for i in range(0, bodies_in_awareness.size()-1):
		if bodies_in_awareness[i] == body:
			bodies_in_awareness.remove(i)
			break