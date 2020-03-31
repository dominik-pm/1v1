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
		
		player.get_damage(body.damage, body.player_fired, bodypart)
	elif body.is_in_group("knife"):
		print("knife is schlitzing")
		if body.swinging:
			var dmg = body.dmg
			if body.alternate_swinging:
				dmg = body.second_dmg 
			player.get_damage(dmg, body.player_fired, "body")
