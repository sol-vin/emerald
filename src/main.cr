require "lapis"
require "./emerald"

# =============================================================================
# Emerald - LibVLC Godot Addon Plugin
# =============================================================================
@[Tool]
node EmeraldPlugin < EditorPlugin do
  def _enter_tree : Void
    Godot.print("==================================================================")
    Godot.print("  [Emerald] LibVLC Multimedia Playback Plugin initialized!")
    begin
      Godot.print("  LibVLC version: #{Emerald::Instance.version}")
    rescue ex
      Godot.print("  LibVLC status: #{ex.message}")
    end
    Godot.print("  Nodes: EmeraldVideoPlayer, EmeraldAudioPlayer, EmeraldVideoPlayer3D")
    Godot.print("==================================================================")
  end

  def _exit_tree : Void
    Godot.print("  [Emerald] LibVLC Multimedia Playback Plugin disabled.")
  end
end
