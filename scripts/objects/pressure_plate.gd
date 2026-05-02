extends Area2D
class_name PressurePlate

@export var target_node_path: NodePath
@export var stay_pressed: bool = true

var _activated: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	if not stay_pressed:
		body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if not _activated and (body.is_in_group("player") or body.is_in_group("movable")):
		_activated = true
		$Sprite2D.frame = 1
		var target = get_node(target_node_path)
		if target and target.has_method("activate"):
			target.activate(true)

func _on_body_exited(body):
	if not stay_pressed and _activated and (body.is_in_group("player") or body.is_in_group("movable")):
		var bodies = get_overlapping_bodies()
		var still_pressed = false
		for b in bodies:
			if b.is_in_group("player") or b.is_in_group("movable"):
				still_pressed = true
				break
		if not still_pressed:
			_activated = false
			$Sprite2D.frame = 0
			var target = get_node(target_node_path)
			if target and target.has_method("activate"):
				target.activate(false)
