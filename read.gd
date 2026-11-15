extends Control

func _ready() -> void:
	%MarkdownLabel.text = Content.markdown_content
	

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
