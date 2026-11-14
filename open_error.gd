extends Control

func _ready() -> void:
	# 先赋文本再弹窗，避免按空文本计算尺寸后再居中
	%ConfirmationDialog.dialog_text = Content.open_file_error
	%ConfirmationDialog.popup_centered()


func _on_button_pressed() -> void:
	queue_free()
