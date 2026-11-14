extends Control

const MAX_BYTES := 8 * 1024 * 1024

func _ready():
	%FileDialog.file_selected.connect(_on_file_selected)
	get_window().files_dropped.connect(_on_files_dropped)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and FileAccess.file_exists(args[0]):
		_on_file_selected(args[0])

func _on_files_dropped(files: PackedStringArray):
	for f in files:
		if f.get_extension().to_lower() in ["md", "markdown"]:
			_on_file_selected(f)
			return

func _on_loadfilebutton_pressed() -> void:
	%FileDialog.popup_centered()
func _on_file_selected(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file != null:
		var file_size = file.get_length()
		if file_size < MAX_BYTES:
			var content = file.get_as_text()
			Content.markdown_content = content
			file.close()
			get_tree().change_scene_to_file("res://read.tscn")
		elif file_size >= MAX_BYTES:
			file.close()
			OS.alert(tr("ALERT_FILE_TOO_LARGE_MSG"), tr("ALERT_FILE_TOO_LARGE_TITLE"))
			return
	else:
		var open_error = preload("res://open_error.tscn").instantiate()
		add_child(open_error)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
