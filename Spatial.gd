extends Spatial

var planet 
var sun
var locked = false

const SPEED_MOVEMENT = .5
const SPEED_ROTATION = 2

var input_movement_vector = Vector2()

func _ready():
	planet = $CSGSphere
	sun = $CSGTorus
	#That sets up the offset, it only needs to be done once, 
	#doing it multiple times will accumulate the offset then to rotate, do:
	
	var t = planet.transform
	t = t.translated(sun.transform.origin + Vector3(0, 0, 10))
	planet.transform = t

var captured_pivot_radius = false
var pivot_radius
var pivot_transform

func _physics_process(delta):
	
	var t = planet.transform
	if Input.is_action_just_pressed("toggle_lock"):
		if not locked:
			locked = true
		else:
			locked = false
			planet.transform.origin = Vector3(0,0,0)
	
	if locked:
		#if you call that in _process, it'll rotate it 
		#by 1 degree every frame around the Z axis
		#rotated(NormalizedVector, Phi in radians)
		if Input.is_action_pressed("move_left"):
			input_movement_vector.x -= 1
		
		if Input.is_action_pressed("move_right"):
			input_movement_vector.x += 1
		
		
		pivot_radius = planet.transform.origin - sun.transform.origin
		print(sun.transform.origin, " ---> ", pivot_radius)
		pivot_transform = Transform(transform.basis, sun.transform.origin)
		t = pivot_transform.rotated( Vector3(0,1,0), deg2rad(input_movement_vector.x * SPEED_ROTATION)).translated(pivot_radius)
	
		if Input.is_action_pressed("move_up"):
			t = t.translated(Vector3(0,0,-SPEED_MOVEMENT) )
		elif Input.is_action_pressed("move_down"):
			t = t.translated(Vector3(0,0,SPEED_MOVEMENT) )
	else:
		captured_pivot_radius = false
		
		if Input.is_action_pressed("move_left"):
			t = t.translated(Vector3(-SPEED_MOVEMENT,0,0) )
		elif Input.is_action_pressed("move_right"):
			t = t.translated(Vector3(SPEED_MOVEMENT,0,0) )
		
		if Input.is_action_pressed("move_up"):
			t = t.translated(Vector3(0,0,-SPEED_MOVEMENT) )
		elif Input.is_action_pressed("move_down"):
			t = t.translated(Vector3(0,0,SPEED_MOVEMENT) )
		
	planet.transform = t
	planet.look_at_from_position(planet.transform.origin, sun.transform.origin, Vector3(0,1,0) )
	input_movement_vector = Vector2()