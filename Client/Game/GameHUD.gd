extends CanvasLayer

onready var killfeed = $Killfeed
onready var clock = $Clock
onready var message_text = $StatusBar/MessageText
onready var scoreboard = $Scoreboard

func _ready():
	scoreboard.hide()
	message_text.text = ""

func _input(event):
	if event.is_action_pressed("open_scoreboard"):
		scoreboard.show()
	elif event.is_action_released("open_scoreboard"):
		scoreboard.hide()

func update_scoreboard(s):
	scoreboard.update_scoreboard(s)

func set_timer(t):
	clock.set_timer(t)

func update_killfeed(killer, victim):
	killfeed.update_feed(killer, victim)

func display_status(msg):
	message_text.text = str(msg)
