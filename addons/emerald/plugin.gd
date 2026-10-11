@tool
extends EditorPlugin

var _loader = null

func _enter_tree():
	print("==================================================================")
	print("  [Emerald] LibVLC Multimedia Playback Plugin initialized!")
	if ClassDB.class_exists("EmeraldVideoPlayer"):
		print("  Native GDExtension nodes: EmeraldVideoPlayer, EmeraldAudioPlayer, EmeraldVideoPlayer3D")

	# Register ResourceFormatLoaderEmerald if not already registered
	var recognized = ResourceLoader.get_recognized_extensions_for_type("EmeraldMediaResource")
	if recognized.is_empty() and ClassDB.class_exists("ResourceFormatLoaderEmerald"):
		_loader = ClassDB.instantiate("ResourceFormatLoaderEmerald")
		if _loader:
			ResourceLoader.add_resource_format_loader(_loader)
			print("  [Emerald] Registered ResourceFormatLoaderEmerald with ResourceLoader")

	# Request EditorFileSystem scan only if not already scanning (prevents interrupting first_scan_filesystem)
	var ei = get_editor_interface()
	if ei:
		var efs = ei.get_resource_filesystem()
		if efs and not efs.is_scanning():
			efs.call_deferred("scan")
	print("==================================================================")

func _exit_tree():
	if _loader:
		ResourceLoader.remove_resource_format_loader(_loader)
		_loader = null
	print("  [Emerald] LibVLC Multimedia Playback Plugin disabled.")
