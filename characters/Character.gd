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

export(Material) var body_material setget set_body_material



var navLevel

export(bool) var draw_path = true
export(bool) var teleport_on_fail = false

const PATH_FAIL_MAX = 3
var path_fail = 0
const MAX_ERRORS = 10
var errors = 0

const INTERVAL_TO_CHECK_DISTANCE_MOVED = 1
var time_distance_moved = 0
var beginning_position:Vector3 = Vector3()
var CHARACTER_STUCK_DEADZONE:float = .2
export var ACCEPTABLE_PATH_DISTANCE:float = .5


# If I cannot access my destination time (whether there is someone in the way or
# I simply cannot get there...then teleport me there.
const DESTINATION_ACCESS_TIME = 6000
var remaining_access_time = DESTINATION_ACCESS_TIME

export var locomotion_speed:float = 1


#############
# Draw Style
export var draw_color:Color = Color(1, 1, 1, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
	orientation=global_transform
	orientation.origin = Vector3()
	navLevel = get_tree().get_root().find_node('Level', true, false)

func set_body_material(mat: Material):
	find_node('SimpleManMesh').set_surface_material(0, mat)


var process_movement : bool = true
func _process_movement(delta):
	
	if not process_movement:
		return

	if typeof(paths) != TYPE_ARRAY:
		$AnimationTree["parameters/Locomotion/blend_position"] = 0
		return

	if paths.empty():
		$AnimationTree["parameters/Locomotion/blend_position"] = 0
		return
		
	$AnimationTree["parameters/Locomotion/blend_position"] = locomotion_speed
	$AnimationTree["parameters/LocomotionTimeScale/scale"] = 1

	if global_transform.origin.distance_to(paths[0]) < ACCEPTABLE_PATH_DISTANCE:
		accumulated_rotation = 0
		paths.remove(0)

		if paths.empty():
			navLevel.path_completed(self)
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
	_process_movement(delta)
	_check_vision(delta)

func generate_paths(destination: Vector3):
	paths = navLevel.generate_path(self, destination)
	if paths and not paths.empty():
		return true

	path_fail = true
	print('Path Fail')
	return false


var find_nearest_waypoint_behind = false

##################
# CHECK VISION
var process_vision : bool = true
func _check_vision(delta):
	
	if not process_vision:
		return
	
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
		
		#if find_nearest_waypoint_behind:
			#var waypoint = grab_random_waypoint()
			#if waypoint:
			#	generate_paths(waypoint)
			#find_nearest_waypoint_behind = false
			#$AreaOfAwareness.monitoring = false

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