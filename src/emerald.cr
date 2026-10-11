require "./emerald/version"
require "./emerald/vlc/lib_vlc"
require "./emerald/vlc/environment"
require "./emerald/vlc/metadata"
require "./emerald/vlc/tracks"
require "./emerald/vlc/equalizer"
require "./emerald/vlc/frame_buffer"
require "./emerald/vlc/event_manager"
require "./emerald/vlc/instance"
require "./emerald/vlc/media"
require "./emerald/vlc/media_player"
require "./emerald/resources/media_resource"
require "./emerald/resources/resource_format_loader"
require "./emerald/nodes/video_player"
require "./emerald/nodes/audio_player"
require "./emerald/nodes/video_player_3d"

# Root namespace for the Emerald library
module Emerald
  alias Instance = VLC::Instance
  alias MediaPlayer = VLC::MediaPlayer
  alias Media = VLC::Media
  alias Equalizer = VLC::Equalizer
  alias Metadata = VLC::Metadata

  # Resolves virtual paths (res:// and user://), local files, and URLs to a format suitable for LibVLC.
  def self.resolve_source_path(path : String) : String
    return "" if path.empty?

    # Resolve Godot virtual paths (res:// and user://)
    if path.starts_with?("res://") || path.starts_with?("user://")
      if !Godot::ProjectSettings.singleton_ptr.null?
        ps = Godot::ProjectSettings.new(Godot::ProjectSettings.singleton_ptr)
        glob = ps.call_str("globalize_path", path).gsub('\\', '/')
        return glob if !glob.empty? && (File.file?(glob) || File.directory?(glob))
      end
      # Standalone fallback: check relative to current working directory
      stripped = path.sub(/^(res|user):\/\//, "")
      return File.expand_path(stripped) if File.file?(stripped)
      return stripped
    end

    # Pass network URLs through untouched
    return path if path =~ %r{^[a-zA-Z][a-zA-Z0-9+-.]*://}

    File.expand_path(path)
  end
end

{% unless flag?(:release) %}
require "./docs"
{% end %}

