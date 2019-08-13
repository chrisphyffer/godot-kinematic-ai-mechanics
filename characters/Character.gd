extends KinematicBody

# THIS IS AN ABSTRACT CLASS. YOU SHOULD NOT INHERIT IT.
class_name Character

################### 
# System Variables
export(bool) var debug_mode


###################
# Character Description
export(bool) var controlled_by_player = true

#### Hostility
# 1 - Will run. 
# 2 - Attacks if attacked. 
# 3 - Attacks if attacked and will chase you
# 4 - Attacks in you are in sight.
enum HOSTILITY_LEVELS { IDLE=0, PREY=1, DEFENSIVE=2, AGRESSIVE=3, HUNTER=4 }

export(HOSTILITY_LEVELS) var hostility_level = HOSTILITY_LEVELS.get('PREY')

export(int) var health = 100


##################
# Field of View
export(float) var fov_height = 1.0
export var field_of_view = 45
export(float) var field_of_view_resolution = 1.0

##################
# Game Controller Variables
var camera : Camera = null
export var point_and_click : bool = true



###################
# Node Specific Variables



# GD Script Enum character type:
# Armature driven? Static Body? :)











var accumulated_rotation = 0
var arrived_at_position = false
var rotated_to_position = false
var orientation = Transform()
var velocity = Vector3()
const GRAVITY = Vector3(0,-9.8, 0)

export(Material) var body_material setget set_body_material






export(bool) var teleport_on_fail = false

const PATH_FAIL_MAX = 3

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
# Navigation
export(NodePath) var navLevelPath
var navLevel

# Debug Path Draw
var draw_path_node:ImmediateGeometry
export(bool) var debug_draw_path = true
export var navigation_draw_color:Color = Color(1, 1, 1, 1)

var navigation_path:Array = []
var path_fail : bool = false



# Called when the node enters the scene tree for the first time.
func _ready():
	orientation=global_transform
	orientation.origin = Vector3()
	navLevel = get_node(navLevelPath)

func set_body_material(mat: Material):
	find_node('SimpleManMesh').set_surface_material(0, mat)


var process_movement : bool = true
func _process_movement(delta):

	if not process_movement:
		return

	if typeof(navigation_path) != TYPE_ARRAY:
		$AnimationTree["parameters/Locomotion/blend_position"] = 0
		return

	if navigation_path.empty():
		$AnimationTree["parameters/Locomotion/blend_position"] = 0
		return

	$AnimationTree["parameters/Locomotion/blend_position"] = locomotion_speed
	$AnimationTree["parameters/LocomotionTimeScale/scale"] = 1

	if global_transform.origin.distance_to(navigation_path[0]) < ACCEPTABLE_PATH_DISTANCE:
		accumulated_rotation = 0
		navigation_path.remove(0)

		if navigation_path.empty():
			do_debug_draw_path(true)
			return

	var t = transform
	navigation_path[0].y = t.origin.y

	var rotTransform = t.looking_at(navigation_path[0], Vector3(0,1,0))
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

func do_debug_draw_path(clear_draw_path_only:bool = false):
	if debug_draw_path:

		if clear_draw_path_only:
			draw_path_node.clear()
			return

		if draw_path_node:
			draw_path_node.clear()
		else:
			draw_path_node = ImmediateGeometry.new()
			get_tree().get_root().add_child(draw_path_node)

		var _m = SpatialMaterial.new()
		_m.albedo_color = navigation_draw_color
		_m.flags_unshaded = true
		_m.flags_use_point_size = true

		draw_path_node.set_material_override(_m)
		draw_path_node.clear()
		draw_path_node.begin(Mesh.PRIMITIVE_POINTS, null)

		draw_path_node.add_vertex(Vector3(navigation_path[0].x, navigation_path[0].y, navigation_path[0].z ) )
		draw_path_node.add_vertex(Vector3(navigation_path[navigation_path.size()-1].x, navigation_path[navigation_path.size()-1].y, navigation_path[navigation_path.size()-1].z ) )
		draw_path_node.end()

		draw_path_node.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
		for x in navigation_path:
			draw_path_node.add_vertex(x)
		draw_path_node.end()

		return draw_path_node


func get_navigation_path(destination: Vector3):
	navigation_path = navLevel.generate_path(self, destination)

	if not typeof(navigation_path) == TYPE_ARRAY:
		path_fail = true

	if navigation_path.empty():
		path_fail = true

	if path_fail:
		return false

	do_debug_draw_path()
	return true

func set_navigation_path(end):
	TYPE_ARRAY
	var _paths = get_navigation_path( end )
	if typeof(_paths) == TYPE_ARRAY:
		navigation_path = _paths



var find_nearest_waypoint_behind = false

##################
# CHECK VISION
var process_vision : bool = true
func _check_vision(delta):

	if not process_vision:
		return

var bodies_in_awareness = []
func _object_entered_area_of_awareness(body):
	bodies_in_awareness.append(body)
	pass

func _object_exited_area_of_awareness(body):
	for i in range(0, bodies_in_awareness.size()-1):
		if bodies_in_awareness[i] == body:
			bodies_in_awareness.remove(i)
			break