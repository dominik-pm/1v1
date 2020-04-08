extends CanvasLayer

onready var killfeed = $Killfeed

func update_killfeed(killer, victim):
	killfeed.update_feed(killer, victim)
