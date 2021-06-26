extends Spatial

export (NodePath) var player_path

const WEAPON_SLOTS = 3

var currently_switching
var selected_weapon = null
var can_fire = true
var reloading = false
var play_anim = false

var player = null
var hud

func _ready():
	currently_switching = false

func init(weapons):
	player = get_node(player_path)
	if player is PuppetPlayer:
		pass
	else:
		hud = player.hud
	
	add_weapons(weapons)
	update_ammo_on_hud()
	
	play_anim = true


func reset(weapons):
	add_weapons(weapons)
	update_ammo_on_hud()

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
					var child = get_child(index).get_child(0)
					get_child(index).remove_child(child)
					child.call_deferred("free")
				var new_weapon = weapon["scene"].instance()
				get_children()[index].add_child(new_weapon)
				new_weapon.item = weapon
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
	if not currently_switching:
		reloading = false
		
		# check if there is a weapon at the slot
		var slot = get_children()[index]
		# check if can select index:
		if slot.get_child_count() == 1:
			if get_current_weapon_index() != index:
				player.unscope()
				currently_switching = true
				update_weapon(index)
				update_ammo_on_hud()
				
				yield(get_tree().create_timer(0.5), "timeout")
				
				currently_switching = false
		else:
			print("no weapon available at slot " + str(index))
func update_weapon(index):
	# tell the player (animations and sound)
	player.switching_weapons(index)
	
	if get_child(index).get_child_count() > 0:
		selected_weapon = get_child(index).get_child(0)
	
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
func shoot(pos, dir, vel_sq):
	if selected_weapon != null:
		if selected_weapon.current_ammo > 0 and not reloading:
			if can_fire:
				dir = get_spread(dir, vel_sq)
				
				player.emit_signal("request_camera_recoil", selected_weapon.current_spraying_spread+selected_weapon.max_spraying_spread)
				player.shooting(dir, selected_weapon.fire_power)
				
				fire_from_pos(pos, dir)
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
	if not currently_switching:
		if selected_weapon != null and selected_weapon.item["slot"] != "KNIFE":
			if not reloading and selected_weapon.current_ammo < selected_weapon.clip_size:
				player.game.reload() # to tell the server
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

func fire_from_pos(pos, dir):
	can_fire = false
	selected_weapon.current_ammo -= 1
	update_ammo_on_hud()
	selected_weapon.shoot(pos, dir)
	
	# can fire again after fire_rate timeout
	yield(get_tree().create_timer(selected_weapon.fire_rate), "timeout")
	can_fire = true

func update_ammo_on_hud():
	if player is PuppetPlayer:
		pass
	else:
		if selected_weapon != null:
			hud.update_ammo(selected_weapon, reloading)
		else:
			hud.hide_ammo()

func get_spread(dir, vel):
	# for the velocity squared, get a value between 0 and 1
	var v = clamp(vel, 0.0, 10.0)/10.0
	# calculate the spread with current moving speed (times 2 to weigh it more)
	var velocity_spread = selected_weapon.moving_spread*v*2
	# the total spread is the moving spread plus the weapons current spraying spread
	var spread = selected_weapon.current_spraying_spread + velocity_spread
	
	# spread would be too high without this
	spread = spread/10.0
	
	randomize()
	var s = Vector3(rand_range(-spread, spread), rand_range(-spread, spread), rand_range(-spread, spread))
	return dir + s
