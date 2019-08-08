extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

class_name Character


func set_paths(paths_arg):
	accumulated_rotation = 0
	paths = paths_arg
	arrived_at_position = false
	rotated_to_position = false
	$AnimationTree["parameters/Locomotion/blend_position"] = 1

var paths = []
var accumulated_rotation = 0
var arrived_at_position = false
var rotated_to_position = false
var orientation = Transform()
var velocity = Vector3()
const GRAVITY = Vector3(0,-9.8, 0)
var next_path = false

export var is_ai = false

export(Material) var body_material setget set_body_material

export(Array, NodePath) var waypoints

var navLevel

# Called when the node enters the scene tree for the first time.
func _ready():
	orientation=global_transform
	orientation.origin = Vector3()
	navLevel = get_tree().get_root().find_node('Level', true, false)

func set_body_material(mat):
	find_node('SimpleManMesh').set_surface_material(0, mat)

func _process_movement(delta):
	if paths.empty():
		$AnimationTree["parameters/Locomotion/blend_position"] = 0
		return

	if global_transform.origin.distance_to(paths[0]) < .5:
		#print(arrived_at_position)
		#arrived_at_position = true
		#rotated_to_position = false
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

	$AnimationTree["parameters/Locomotion/blend_position"] = 1

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

var time_test = 0
const MAX_TIME_TEST = 2
func _physics_process(delta):
	_process_movement(delta)

	if is_ai:
		var waypoint = get_node( waypoints[ int( round( rand_range( 0, waypoints.size() - 1 ) ) ) ] )
	
		if paths.empty(): #and time_test > MAX_TIME_TEST:
			paths = navLevel.generate_path(self, waypoint)
			#time_test = 0
			print('Update Nav Level')
			
		#time_test += delta