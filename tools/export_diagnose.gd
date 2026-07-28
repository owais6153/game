@tool
extends EditorScript

func _run() -> void:
	var exporter := EditorExport.get_singleton()
	var platforms := exporter.get_export_platforms()
	for platform in platforms:
		print("PLATFORM=", platform.get_name())
		for preset in platform.get_current_presets():
			print("PRESET=", preset.get_preset_name())
			print("VALID=", platform.has_valid_export_configuration(preset, true))
			for i in platform.get_message_count():
				print("MESSAGE=", platform.get_message_text(i))
