extends Resource

class_name Attack

enum ATTACK_TYPE { RANGED, FRONTAL_ASSAULT }
#export(ATTACK_TYPE) var attack_type = ATTACK_TYPE.get('FRONTAL_ASSAULT')
#export(float) var min_distance:float = 0.0 # Float, ignored if ranged
#export(float) var travel_speed:float = 0.0
#export(String) var animation:String = 'punch'
#export(Array, AttackRule) var rules = []

var name = ''; # Name of Attack.
var attack_type = ATTACK_TYPE.get('FRONTAL_ASSAULT')
var min_distance:float = 0.0 # Float, ignored if ranged
var striking_distance:float = 0.0
var travel_speed:float = 0.0
var animation:String = 'punch'
var rules = []

# Constructor
func _init(name:String, attack_type:int, min_distance:float, travel_speed:float,animation:String,rules:Array):
	self.name = name
	self.attack_type = attack_type
	self.min_distance = min_distance # Float, ignored if ranged
	self.striking_distance = min_distance
	self.travel_speed = travel_speed
	self.animation = animation
	self.rules = rules