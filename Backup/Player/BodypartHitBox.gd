extends Area

var player = null

func _ready():
	player = get_parent().get_parent().get_parent().get_parent()
	connect("body_entered", self, "_on_playerhitbox_body_entered")

func _on_playerhitbox_body_entered(body):
	if body is GenericBullet:
		body.hit_player()
		
		# the area is called "playerhitbox_head" and the player wants just "head"
		var bodypart = name.substr(name.find("_")+1)
		
		# maybe better system for this
		player.get_parent().get_parent().get_node("Game").player_hit_player(body.player_fired, player.name, body.damage, bodypart)
	
	elif body.is_in_group("knife"):
		var knife = body.knife
		if not knife.already_hit and knife.swinging:
			knife.already_hit = true
			var dmg = knife.damage
			if knife.alternate_swinging:
				dmg = knife.second_damage
			player.get_damage(dmg, knife.player_fired, "body")
