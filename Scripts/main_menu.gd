extends Control

@onready var grid_container = $GridContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	search_maps("res://Scenes/Maps/")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func search_maps(chemin):
	var repertoire = DirAccess.open(chemin)
	if repertoire:
		repertoire.list_dir_begin()
		var nom_fichier = repertoire.get_next()
		while nom_fichier!= "":
			if !repertoire.current_is_dir():
				print("Map trouvé : " + nom_fichier)
				var container = CenterContainer.new()
				grid_container.add_child(container)
				var button = Button.new()
				button.text = nom_fichier
				container.add_child(button)
				
			nom_fichier = repertoire.get_next()
	else:
		print("Une erreur s'est produite lors de l'accès au chemin.")
