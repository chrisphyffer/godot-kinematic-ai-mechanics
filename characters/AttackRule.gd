class_name AttackRule

var name:String = 'distance' # Distance/character_out_of_fov/character_in_fov/max_health
var greater_than : bool = false
var less_than : bool = true
var at_health : float =  100.00
var distance : float = 200000.0

func _init(name:String = 'distance', distance:float=200000, less_than:bool= true, greater_than:bool=false, at_health:float = 0.0):
	self.name = name
	self.greater_than = greater_than
	self.less_than = less_than
	self.at_health = at_health
	self.distance = distance