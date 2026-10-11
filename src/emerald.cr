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
end

{% unless flag?(:release) %}
require "./docs"
{% end %}

