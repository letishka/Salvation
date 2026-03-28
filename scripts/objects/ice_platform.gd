extends StaticBody2D

func _ready():
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(queue_free)
