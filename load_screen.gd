extends CanvasLayer

@export var progress_bar : ProgressBar
@export var next_scene_path : String
var progress : Array[float] = []

# Called when the node enters the scene tree for the first time.
func load_scene():
	ResourceLoader.load_threaded_request(next_scene_path)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var status = ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var pct = progress[0] * 100
			progress_bar.value = pct
		ResourceLoader.THREAD_LOAD_LOADED:
			var scene = ResourceLoader.load_threaded_get(next_scene_path)
			get_tree().change_scene_to_packed(scene)
