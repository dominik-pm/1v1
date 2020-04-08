extends Spatial

export (NodePath) var player_path

const WEAPON_SLOTS = 3

var selected_weapon = null
var can_fire = true
var reloading = false
var play_anim = false

var player
var hud

func _ready():
	player = get_node(player_path)

func init(weapons):
	hud = get_parent().hud
	
	add_weapons(weapons)
	
	update_ammo_on_hud()
	
	play_anim = true
	
	# reset(), if you only want to start with the starter weapon 
	# (for testing you start with all guns attaches to this node)
	#reset()

func reset(weapons):
	remove_all()
	add_weapons(weapons)
	update_ammo_on_hud()
func remove_all():
	# geht ned?!?!?!?!?
	for slot in get_children():
		if slot.get_child_count() > 0:
			slot.get_child(0).queue_free()
	selected_weapon = null

func add_weapons(weapons):
	for weapon_id in weapons:
		var weapon = ItemDB.get_item(weapon_id)
		if weapon["slot"] != "error":
			var index = null
			var slot = weapon["slot"]
			if slot == "PRIMARY":
				index = 0
			if slot == "SECONDARY":
				index = 1
			elif slot == "KNIFE":
				index = 2
			
			if index != null:
				if get_children()[index].get_child_count() > 0: 
					get_children()[index].get_child(0).queue_free()
				var new_weapon = weapon["scene"].instance()
				new_weapon.item = weapon
				get_children()[index].add_child(new_weapon)
			else:
				print("couldnt add weapon because of a database problem")
		else:
			print("no weapon with weapon_id: " + str(weapon_id))
	update_weapon(2)

func get_all_item_ids():
	var ids = []
	for slot in get_children():
		if slot.get_child_count() > 0:
			var weapon = slot.get_children()[0]
			ids.push_back(weapon.name.to_lower())

func is_selected_weapon_scopeable():
	if selected_weapon == null:
		return false
	else:
		return selected_weapon.scopeable

func get_selected_weapon_scopefov():
	return selected_weapon.scope_fov

func select_weapon(index):
	# check if there is a weapon at the slot
	var slot = get_children()[index]
	if slot.get_child_count() == 1:
		if get_current_weapon_index() != index:
			# tell the player (animations and sound)
			player.switching_weapons(index)
			
			# select the new weapon after half of the drawing time
			yield(get_tree().create_timer(0.25), "timeout")
			
			hide_all_items()
			player.unscope()
			selected_weapon = slot.get_children()[0]
			selected_weapon.visible = true
			update_ammo_on_hud()
	else:
		print("no weapon available at slot " + str(index))
func update_weapon(index):
	# tell the player (animations and sound)
	player.switching_weapons(index)
	
	# select the new weapon after half of the drawing time
	yield(get_tree().create_timer(0.25), "timeout")
	
	hide_all_items()
	selected_weapon = get_child(index).get_child(0)
	selected_weapon.visible = true
#func select_weapon(index):
#	if !global.is_offline:
#		for id in Network.players:
#			rpc_id(id, '_select_weapon', index)
#	else:
#		_select_weapon(index)
#	
#	# display new weapons ammo in hud
#	update_ammo_on_hud()
#	
#	# unscope
#	get_parent().player.unscope()
#remotesync func _select_weapon(index):
#	# check if there is a weapon at the slot
#	var slot = get_children()[index]
#	if slot.get_child_count() == 1:
#		if get_current_weapon_index() != index:
#			print("changing weapon to index " + str(index))
#			
#			# change weapon in manager
#			_hide_all_items()
#			selected_weapon = slot.get_children()[0]
#			selected_weapon.visible = true
#	else:
#		print("no weapon available at slot " + str(index))

func select_slot(slot):
	var slots = get_children()
	for i in range(0, slots.size()):
		if slots[i].get_child_count() > 0:
			var weapon = slots[i].get_children()[0]
			var cur_slot = weapon.item["slot"]
			if cur_slot == slot:
				select_weapon(i)
				return
func next_weapon():
	# only if a weapon is already selected
	if selected_weapon != null:
		var index = 0
		var weapon_count = get_weapon_count()
		if weapon_count > 0:
			var curr_index = get_current_weapon_index()
			
			if curr_index == weapon_count-1: # check if on last index
				index = 0
			else:
				index = curr_index + 1
			
			select_weapon(index)
func previous_weapon():
	# only if a weapon is already selected
	if selected_weapon != null:
		var index = 0
		var weapon_count = get_weapon_count()
		if weapon_count > 0:
			var curr_index = get_current_weapon_index()
			
			if curr_index == 0: # check if on first slot
				index = weapon_count-1
			else:
				index = curr_index - 1
			
			select_weapon(index)

func get_current_weapon_index():
	var index = null
	var slots = get_children()
	for i in range(0, slots.size()):
		if slots[i].get_child_count() > 0:
			var weapon = slots[i].get_children()[0]
			if weapon == selected_weapon:
				index = i
	return index
func get_all_weapons():
	var weapons = []
	for slot in get_children():
		if slot.get_child_count() > 0:
			var weapon = slot.get_children()[0]
			weapons.push_back(weapon)
	return weapons
func get_weapon_count():
	var count = 0
	for slot in get_children():
		if slot.get_child_count() > 0:
			count += 1
	return count

func hide_all_items():
	selected_weapon = null
	
	for slot in get_children():
		if slot.get_child_count() > 0:
			var weapon = slot.get_children()[0]
			weapon.visible = false

#func hide_all_items():
#	if !global.is_offline:
#		for id in Network.players:
#			rpc_id(id, "_hide_all_items")
#	else:
#		_hide_all_items()
#remotesync func _hide_all_items():
#	selected_weapon = null
#	
#	for slot in get_children():
#		if slot.get_child_count() > 0:
#			var weapon = slot.get_children()[0]
#			weapon.visible = false

# shooting/reloading
func shoot(pos, dir, velocity):
	if selected_weapon != null:
		if selected_weapon.current_ammo > 0 and not reloading:
			if can_fire:
				dir = get_spread(dir, velocity)
				
				player.emit_signal("request_camera_recoil", selected_weapon.current_spraying_spread+selected_weapon.max_spraying_spread)
				player.shooting(dir, selected_weapon.fire_power)
				
				fire(pos, dir)
		else:
			reload()

func knife(is_alternate):
	if selected_weapon != null:
		if selected_weapon.item["slot"] == "KNIFE":
			if can_fire:
				can_fire = false
				player.knifing(is_alternate)
				selected_weapon.knife(is_alternate)
				
				# can knife again after fire_rate timeout
				yield(get_tree().create_timer(selected_weapon.fire_rate), "timeout")
				can_fire = true
		else:
			print("WTF ITEM IS DOCH NED KNIFE (is eig schau im player gecheckt)")

func reload():
	if not reloading and selected_weapon.current_ammo < selected_weapon.clip_size:
		player.reloading() # for anim and sound
		reloading = true
		var reloading_weapon = selected_weapon
		update_ammo_on_hud()
		
		yield(get_tree().create_timer(selected_weapon.reload_rate), "timeout")
		
		# check if weapon still there :) (player could have been killed or weapon could be switched)
		if selected_weapon != null and reloading_weapon == selected_weapon:
			selected_weapon.current_ammo = selected_weapon.clip_size
			
			reloading = false
			update_ammo_on_hud()

func fire(pos, dir):
	can_fire = false
	selected_weapon.current_ammo -= 1
	update_ammo_on_hud()
	selected_weapon.shoot(pos, dir)
	
	# can fire again after fire_rate timeout
	yield(get_tree().create_timer(selected_weapon.fire_rate), "timeout")
	can_fire = true

func update_ammo_on_hud():
	if selected_weapon != null:
		hud.update_ammo(selected_weapon, reloading)
	else:
		hud.hide_ammo()


func get_spread(dir, vel):
	# more spread when moving
	var velocity_spread = selected_weapon.moving_spread*vel # velocity = between 0-1,... (not exact)
	var spread = selected_weapon.current_spraying_spread + velocity_spread
	
	
	return dir
	
	"""
	## ------
	
	#if old_object != null:
	#	old_object.queue_free()
	##var object = obj.instance()
	#var object = obj.instance()
	#get_node(global.GAME_PATH).add_child(object)
	
	##print(d)
	#object.rotation = d
	##print(object.rotation)
	#object.global_transform.origin = Vector3(0, 50, 0)
	
	var d = dir
	var r
	randomize()
	
	# random up and down spread
	r = sin(randf()*2*PI)*s/100 # r = [-1.0;1.0] multiplied with spread/100
	#object.rotate_object_local(Vector3(1,0,0), r*2*PI)
	
	# random left and right spread
	r = sin(randf()*2*PI)*s/100
	#object.rotate_object_local(Vector3(0,1,0), r*2*PI)
	
	#dir = object.rotation
	d = d.normalized()
	
	#old_object = object
	
	return d
	"""
