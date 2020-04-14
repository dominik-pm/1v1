extends CenterContainer

var scoreboard_entry = preload("res://Scenes/Scoreboard/ScoreboardEntry.tscn")

onready var score_entries = $TextureRect/VBoxContainer

func update_scoreboard(scores):
	# scores look like this
	#var scores = {
	#	"nitrogen": {
	#		"kills": 10,
	#		"deaths": 3
	#	}
	#}
	# delete all previous scores (maybe find a better system, to just update)
	# -> could be done with naming the entry like the player and then updating the score
	for score_entry in score_entries.get_children():
		if score_entry.name != "Header":
			score_entries.remove_child(score_entry)
			score_entry.queue_free()
	
	# add the new entries
	for score in scores:
		var new_entry = scoreboard_entry.instance()
		new_entry.name = score
		new_entry.update_scoreboard(score, scores[score].kills, scores[score].deaths)
		score_entries.add_child(new_entry)
		print(new_entry.name)

#func update_kill_count(kill_count):
#	kill_count_label.text = str(kill_count)

#func update_death_count(death_count):
#	death_count_label.text = str(death_count)
