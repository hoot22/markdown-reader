extends Control

func  _ready() -> void:
	%errorLabel.text = Content.open_file_error

func _on_button_pressed() -> void:
	queue_free()
