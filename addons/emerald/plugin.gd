@tool
extends EditorPlugin

func _enter_tree():
	print("==================================================================")
	print("  [Emerald] LibVLC Multimedia Playback Plugin initialized!")
	if ClassDB.class_exists("EmeraldVideoPlayer"):
		print("  Native GDExtension nodes: EmeraldVideoPlayer, EmeraldAudioPlayer, EmeraldVideoPlayer3D")
	print("==================================================================")

func _exit_tree():
	print("  [Emerald] LibVLC Multimedia Playback Plugin disabled.")
