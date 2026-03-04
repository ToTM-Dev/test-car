extends Control

@export_dir var map_dir_path
@onready var grid_container = $Panel2/GridContainer

var Buttons : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode =Input.MOUSE_MODE_VISIBLE
	search_maps(map_dir_path)

func search_maps(chemin):
	var repertoire = DirAccess.open(chemin)
	if repertoire:
		repertoire.list_dir_begin()
		var nom_fichier = repertoire.get_next()
		while nom_fichier!= "":
			if !repertoire.current_is_dir() and nom_fichier[-1] == "n":
				print("Map trouvé : " + nom_fichier)
				_add_maps_buttons(chemin, nom_fichier)
				#button.connect("pressed", _change_to_next_scene)
				
			nom_fichier = repertoire.get_next()
	else:
		print("Une erreur s'est produite lors de l'accès au chemin.")

func _add_maps_buttons(chemin : String, nom_fichier : String):
	var container = CenterContainer.new()
	grid_container.add_child(container)
	var button = SceneChangerButton.new()
	button.text = nom_fichier.left(-5).capitalize()
	container.add_child(button)
	button.next_scene_path = chemin + "/" + nom_fichier
