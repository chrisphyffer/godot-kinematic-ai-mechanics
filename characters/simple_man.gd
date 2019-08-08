extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"




func set_paths(paths_arg):
	value = 0
	paths = paths_arg
	arrived_at_position = false
	rotated_to_position = false
	$AnimationTree["parameters/Locomotion/blend_position"] = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	orientation=global_transform
	orientation.origin = Vector3()

var paths = []
var value = 0
var arrived_at_position = false
var rotated_to_position = false
var orientation = Transform()
var velocity = Vector3()
const GRAVITY = Vector3(0,0,0) #Vector3(0,-9.8, 0)

func _physics_process(delta):

	if paths.empty():
		$AnimationTree["parameters/Locomotion/blend_position"] = 0
		return
		
	if global_transform.origin.distance_to(paths[0]) < .3:
		arrived_at_position = true
		paths.remove(paths.size() - 1)
		return

	#if rotated_to_position and not arrived_at_position:

	orientation.basis = global_transform.basis

	$AnimationTree["parameters/Locomotion/blend_position"] = 1

	var root_motion = $AnimationTree.get_root_motion_transform()

	# apply root motion to orientation
	orientation *= root_motion

	var h_velocity = orientation.origin / delta
	velocity.x = -h_velocity.x # NEGATIVES DUE TO FLIPPED Z FRONT...
	velocity.z = -h_velocity.z # NEGATIVES DUE TO FLIPPED Z FRONT...
	velocity += GRAVITY * delta
	velocity = move_and_slide(velocity,Vector3(0,1,0))

	orientation.origin = Vector3() #clear accumulated root motion displacement (was applied to speed)
	orientation = orientation.orthonormalized() # orthonormalize orientation

	global_transform.basis = orientation.basis


	if not paths.empty() and not rotated_to_position and not arrived_at_position:
	
		var t = transform
	
		var lastPosition = t.origin
	
		var rotTransform = transform.looking_at(paths[0], Vector3(0,1,0))
		var thisRotation = Quat(t.basis).slerp(rotTransform.basis, value)
	
		value += delta
	
		if value>1:
			value = 1
			rotated_to_position = true
	
		set_transform(Transform(thisRotation,t.origin))

		#print('Paths Not Empty: ', delta)

		#transform.basis.rotated( Vector(0,1,0) )
		#t = look_at(paths[0], Vector3(0,1,0)) # Global Space
		#t = t.rotated( Vector3(0,1,0), PI/2 )

		#transform = t

		#orientation.origin = Vector3() # Clear accumulated root motion displacement (was applied to speed)
		#orientation = orientation.orthonormalized() # orthonormalize orientation

		#$"Scene Root".global_transform.basis = orientation.basis
	#else:
		#value = 0
		#print('Paths now empty')


	pass


