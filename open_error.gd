extends Control

func _ready() -> void:
	%ConfirmationDialog.dialog_text = Content.open_file_error
	%ConfirmationDialog.popup_centered()


func _on_button_pressed() -> void:
	queue_free()
