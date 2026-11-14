extends Control

func _on_loadfilebutton_pressed() -> void:
	%FileDialog.popup_centered()
func _ready():
	%FileDialog.file_selected.connect(_on_file_selected)
func _on_file_selected(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file != null:
		var content = file.get_as_text()
		Content.markdown_content = content
		get_tree().change_scene_to_file("res://read.tscn")
	else:
		print("打开文件失败！错误码: ", FileAccess.get_open_error())


func _on_quit_button_pressed() -> void:
	get_tree().quit()
