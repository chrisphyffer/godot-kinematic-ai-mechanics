extends Spatial



const ROTATION_SPEED = .3
#const ROTATION_DELAY_PERIOD = .1 # If other characters are super fast and this one can't catch up.
var rotation_delayed = 0
var done_rotating:bool
var accum_rotation = 0.0









const QUAT_EQUIVALENCE_DEADZONE:float = .15
var looked_around_for_character = false
var look_around_rotation = false

var go_reverse = false
















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



	
	
	
	


