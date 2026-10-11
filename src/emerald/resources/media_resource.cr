require "lapis"
require "../vlc/*"

# Godot Resource representing a multimedia asset (video or audio) powered by LibVLC.
# Provides in-engine metadata inspection (duration, resolution, channels, tags)
# and seamlessly connects file formats like .mp4, .mkv, .webm, etc. to Godot's FileSystem dock.
@[Tool]
node EmeraldMediaResource < Resource do
  @[Export]
  property file_path : String = ""

  @[Export]
  property duration_ms : Int64 = 0_i64

  @[Export]
  property width : Int32 = 0_i32

  @[Export]
  property height : Int32 = 0_i32

  @[Export]
  property title : String = ""

  @[Export]
  property artist : String = ""

  @[Export]
  property album : String = ""

  @[Export]
  property is_video : Bool = true

  @[Export]
  property audio_tracks_count : Int32 = 0_i32

  @[Export]
  property subtitle_tracks_count : Int32 = 0_i32

  # Duration formatted as human-readable mm:ss or hh:mm:ss
  def formatted_duration : String
    total_seconds = duration_ms // 1000_i64
    hours = total_seconds // 3600_i64
    minutes = (total_seconds % 3600_i64) // 60_i64
    seconds = total_seconds % 60_i64
    if hours > 0
      sprintf("%02d:%02d:%02d", hours, minutes, seconds)
    else
      sprintf("%02d:%02d", minutes, seconds)
    end
  end

  # Resolution formatted as "WIDTHxHEIGHT" (e.g. "1920x1080")
  def resolution : String
    "#{width}x#{height}"
  end

  # Populates media metadata using LibVLC media parser
  def populate_metadata! : Void
    return if file_path.empty?

    begin
      resolved = Emerald.resolve_source_path(file_path)
      return unless File.file?(resolved)

      media = Emerald::VLC::Media.new(resolved)
      if media.parse(1500)
        self.duration_ms = media.duration_ms if media.duration_ms > 0
        meta = media.metadata
        self.title = meta.title || ""
        self.artist = meta.artist || ""
        self.album = meta.album || ""

        vtracks = media.video_tracks
        atracks = media.audio_tracks
        stracks = media.subtitle_tracks

        self.audio_tracks_count = atracks.size
        self.subtitle_tracks_count = stracks.size

        if first_video = vtracks.first?
          self.is_video = true
          self.width = first_video.width.to_i32
          self.height = first_video.height.to_i32
        else
          self.is_video = false
          self.width = 0_i32
          self.height = 0_i32
        end
      end
    rescue
      # Graceful fallback if LibVLC is unavailable during import/indexing
    end
  end
end

module Emerald
  alias MediaResource = EmeraldMediaResource
end
