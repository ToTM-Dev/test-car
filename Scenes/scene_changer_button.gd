extends Button
class_name SceneChangerButton

var next_scene_path : String

func  _ready() -> void:
	connect("pressed", _change_to_next_scene)

func _change_to_next_scene():
	LoadScreen.visible = true
	LoadScreen.next_scene_path = next_scene_path
	LoadScreen.load_scene()
