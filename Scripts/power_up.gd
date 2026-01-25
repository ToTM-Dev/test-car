extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("new_animation")


func _on_body_entered(body: Node3D) -> void:
	if body is RaycastCar:
		body.animaton_player.play("show_gun")
