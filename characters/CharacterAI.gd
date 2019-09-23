extends Node

class_name CharacterAI

var me:Spatial = null
var awareness:Spatial = null

var find_nearest_waypoint_behind = false

var anim_tree_player = false

func _ready():
	me = get_parent()
	anim_tree_player = get_parent().get_node("AnimationTree")
	awareness = get_parent().get_node('Awareness')
	
	if me.controlled_by_player:
		set_physics_process(false)
		return
	
	anim_tree_player["parameters/Locomotion/blend_position"] = 0
	#$AnimationTree["parameters/Locomotion/blend_position"] = 1
	
	

var on_alert:bool = false
var sweep_for_player_in_range:bool = false
var battle_mode:bool = false
var chosen_attack = false

var duration_search_for_target = 0.0


func _physics_process(delta):
	
	if me.is_attacking:
		me.echo('I am attacking', true)
	
	if me.path_fail:
		print('Path Failure')
		me.process_movement = false
		return
	
	me.echo('My hostility level is : ' + str(me.hostility_level))
	
	if me.hostility_level == me.HOSTILITY_LEVELS.HUNTER:
		
		if awareness.i_can_see_the_character:
			do_battle()
			duration_search_for_target = 0
		
		# Character is here somewhere...
		if battle_mode and awareness.target_character and not awareness.i_can_see_the_character:
			me.echo('This character must be behind me, around my field of vision..', true)
			# Travel to whether (the character was) - a stop distance. This way, they can go
			# around a wall to see if the character is still there.
			duration_search_for_target += delta
			
		elif battle_mode and not awareness.target_character:
			me.echo('This character is far, so I must be on alert...', true)
			on_alert = true
			duration_search_for_target += delta
	
	if duration_search_for_target >= me.time_to_search_for_target:
		me.echo('I am done trying to find target, going back to normal routine.')
		battle_mode = false
		duration_search_for_target = 0
	
	if me.patrol_waypoints and not battle_mode:
		me.echo('On Patrol Now...', true)
		if me.navigation_path.empty():
			me.echo('Patrolling Navigation Path')
			var waypoint = grab_random_waypoint()
	
			if not waypoint:
				me.process_movement = false
				return
			
			if me.set_navigation_path( waypoint.get_translation() ):
				me.set_travel_speed(1.0)
				me.process_movement = true
			else:
				me.process_movement = false
				return
				# Try again, otherwise, just idle this pawn.
	
			me.remaining_access_time = me.DESTINATION_ACCESS_TIME


var is_charging = false
func do_battle():
	
	me.echo('Engaging In Battle..', true)
	battle_mode = true
	
	if me.is_attacking:
		return
	
	# Character Personality
	# What attacks the character prefers
	# 1.) Is this character more of a ranged person
	# 2.) Does this character have a target character who's personality
	#     this character can exploit?
	#var chosen_attack = false
	#for p in range(possible_attacks.size()):
	#	if possible_attacks[p].attack_type == 'ranged':
	#		pass
	
	# Choose a random attack, ask programmer for probability formula
	#var sum_chance = 0.0
	#var chance_ratio = 0.0
	#for i in range(possible_attacks.size()):
	#	sum_chance += possible_attacks[i].chance
	#	chance_ratio = sum_chance / 100
	
	if not chosen_attack:
		chosen_attack = choose_attack()
		
	if not chosen_attack:
		me.echo("I can't attack this character. !Roar of frustration!...", true)
		return

	if chosen_attack.attack_type == Attack.ATTACK_TYPE.RANGED:
		# Stay where you are. Play whatever animation is specified
		# play(me.attack_list[i].animation)
		# Let the animation call the necessary particle fx and character specific functions.
		
		me.echo('I choose a ranged Attack: ' + str(chosen_attack), true)
		me.clear_navigation_path()
		me.set_travel_speed(0)
		attack()
			
	elif chosen_attack.attack_type == Attack.ATTACK_TYPE.FRONTAL_ASSAULT:
		me.echo('I choose a Frontal Attack: ' + str(chosen_attack), true)
		
		charge_to_attack()
		
		# Am I within Striking Distance?
		if not is_charging:
			attack()
			

# Get within Striking Distance, Run into player to attack!
func charge_to_attack():
	is_charging = true
	
	var target_location = awareness.target_character.transform.origin
	var PA = (target_location - me.transform.origin)
	
	# When I reach this character's destination, fuk him up.
	#if vec_dist_for_anim <= chosen_attack.min_distance:
	if PA.length() <= chosen_attack.striking_distance:
		me.echo('I am within distance to attack this character.', true)
		me.clear_navigation_path()
		me.set_travel_speed(0)
		is_charging = false
	else:
		#me.navigation_path[me.navigation_path.size()-1] = vec_dist_for_anim
		me.set_navigation_path(target_location)
		me.set_travel_speed(chosen_attack.travel_speed)
		me.echo('I ('+str(round(PA.length()))+') must meet the minimum distance of ('+str(chosen_attack.min_distance)+') to attack this character.', true)
		#me.echo('I '+str(me.transform.origin)+' @ ('+str(PA.length())+')must meet the minimum distance of ('+str(chosen_attack.min_distance)+') to attack this character ' + str(target_location), true)

func choose_attack():
	
	me.echo('Choosing an appropriate attack.', true)
	
	# Figure out what kind of attack to perform.
	# Grab the distance that the attack may affect. for example, if my arm reach
	# to punch the character's origin is 2.0, then subtract 2.0 from the magnitude
	# of the vector that arrives at the character's origin.
	
	# Factors that determine usable attacks:
	# 1.) How far is the player? (Not necessary if this player is a melee player)
	# 2.) How much health do I have left?
	# 3.) Is the player behind me? Must I do a tornado? An instant teleport?
	#     run toward the character based on hearing and intuition?
	var possible_attacks = []
	var rules_failed = {}
	var target_pos = awareness.target_character.transform.origin
	for attack in me.attack_list:
		var rules =  attack.rules
		var all_rules_met = true
		
		if not rules_failed.get(attack.name):
			rules_failed[attack.name] = Array()
			pass
		
		for rule in rules:
			if rule['name'] == 'distance':
				if rule['less_than'] and not \
					target_pos.distance_to(me.transform.origin) < rule['distance']:
						rules_failed[attack.name].append(\
							str(target_pos.distance_to(me.transform.origin)) + ' distance less_than ' + str(rule['distance']) )
						all_rules_met = false
						break
				if rule['greater_than'] and not \
					target_pos.distance_to(me.transform.origin) > rule['distance']:
						rules_failed[attack.name].append(\
							str(target_pos.distance_to(me.transform.origin)) + ' distance greater_than ' + str(rule['distance']) )
						all_rules_met = false
						break
			
			if rule['name'] == 'character_out_of_fov' and awareness.i_can_see_the_character:
				rules_failed[attack.name].append(rule['name'])
				all_rules_met = false
				break
				
			if rule['name'] == 'character_in_fov' and not awareness.i_can_see_the_character:
				rules_failed[attack.name].append(rule['name'])
				all_rules_met = false
				break
			
			if rule['name'] == 'max_health' and me.health > rule['at_health']:
				rules_failed[attack.name].append(rule['name'])
				all_rules_met = false
				break
			
		if all_rules_met:
			possible_attacks.append(attack)
	
	if not possible_attacks.empty():
		me.echo('I have '+str(possible_attacks.size())+' attacks available to use.', true)
		
		var attacks_from_strategy = []
		for attack in possible_attacks:
			me.echo('ATTACK STRATEGY: ' + str(attack.attack_type) + ' ' + str(attack.ATTACK_TYPE.RANGED))
			me.echo('BATTLE POSITION: ' + str(me.battle_position) + ' ' + str(Character.BATTLE_POSITION.RANGED))
			if attack.attack_type == Attack.ATTACK_TYPE.RANGED and\
				me.battle_position == Character.BATTLE_POSITION.RANGED:
					attacks_from_strategy.append(attack)
		
		if not attacks_from_strategy.empty():
			me.echo('Attacking from strategy..')
			return attacks_from_strategy[rand_range(0, attacks_from_strategy.size()-1) ]
		
		me.echo('No attacks from strategy...')
		return possible_attacks[rand_range(0, possible_attacks.size()-1) ]
	else:
		me.echo('I have no possible attacks available to me..', true)
		print(rules_failed)
		for failed in rules_failed:
			me.echo(str(failed), true)
		# I can't attack this character now...
		return false


func attack():
	# Spend My Attack
	if not me.is_attacking:
		anim_tree_player["parameters/"+ chosen_attack.animation +"/active"] = true
		chosen_attack = false


func ____UNUSED_physics_process(delta):

	# Is our character unable to reach their destination in time?
	if me.remaining_access_time <= 0:
		me.remaining_access_time = me.DESTINATION_ACCESS_TIME

		if me.teleport_on_fail:
			me.global_transform.origin = me.navigation_path[me.navigation_path.size()-1]
			me.navigation_path = []
		else:
			var waypoint = grab_random_waypoint()
			if not waypoint:
				me.process_movement = false
				return

			if not me.get_navigation_path( waypoint.get_translation() ):
				me.process_movement = false
				return
				
		me.echo('Could Not reach destination in time.. Teleporting: ', me.teleport_on_fail)

	me.remaining_access_time -= delta

	# Is our character stuck?
	me.time_distance_moved += delta

	if me.time_distance_moved >= me.INTERVAL_TO_CHECK_DISTANCE_MOVED: #If one second has elapsed
		var total_position = me.transform.origin - me.beginning_position # Generate a Vector difference between the two.
		if total_position.length() < me.CHARACTER_STUCK_DEADZONE: # The character might be stuck.

			# Find nearest waypoint behind the character.
			find_nearest_waypoint_behind = true

			#get_navigation_path( grab_random_waypoint() )

		me.beginning_position = me.transform.origin # Record this beginning position
		me.time_distance_moved = 0

func grab_random_waypoint():
	if me.waypoints.empty():
		return false

	var waypoint = me.waypoints[ int( round( rand_range( 0, me.waypoints.size() - 1 ) ) ) ].get_name(1)
	#find_node is slow...may remove later
	#print(me.waypoints[ int( round( rand_range( 0, me.waypoints.size() - 1 ) ) ) ].get_name(1))
	return get_tree().get_root().find_node(waypoint, true, false) 