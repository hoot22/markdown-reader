extends Control

const TextCodec: GDScript = preload("res://text_codec.gd")
const MarkdownImagePaths: GDScript = preload("res://markdown_image_paths.gd")
const MAX_BYTES: int = 8 * 1024 * 1024
const MARKDOWN_EXTENSIONS: Array[String] = ["md", "markdown"]

func _ready() -> void:
	%FileDialog.file_selected.connect(_on_file_selected)
	get_window().files_dropped.connect(_on_files_dropped)
	var cmdline_path: String = _md_from_cmdline()
	if not cmdline_path.is_empty():
		_on_file_selected.call_deferred(cmdline_path)


func _md_from_cmdline() -> String:
	for arg: String in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		if arg.begins_with("-"):
			continue
		if FileAccess.file_exists(arg) and arg.get_extension().to_lower() in MARKDOWN_EXTENSIONS:
			return arg
	return ""


func _on_files_dropped(files: PackedStringArray) -> void:
	for f: String in files:
		if f.get_extension().to_lower() in MARKDOWN_EXTENSIONS:
			_on_file_selected(f)
			return


func _on_loadfilebutton_pressed() -> void:
	%FileDialog.popup_centered()


func _on_file_selected(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		Content.open_file_error = str(FileAccess.get_open_error())
		var open_error: Node = preload("res://open_error.tscn").instantiate()
		add_child(open_error)
		return
	var file_size: int = file.get_length()
	if file_size >= MAX_BYTES:
		file.close()
		OS.alert(tr("ALERT_FILE_TOO_LARGE_MSG"), tr("ALERT_FILE_TOO_LARGE_TITLE"))
		return
	var content: String = TextCodec.decode(file.get_buffer(file_size))
	file.close()
	# 相对路径的图片按 .md 所在目录补成绝对路径
	var base_dir: String = path.replace("\\", "/").get_base_dir()
	Content.markdown_content = MarkdownImagePaths.rewrite(content, base_dir)
	get_tree().change_scene_to_file("res://read.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()
