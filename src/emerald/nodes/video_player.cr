require "lapis"
require "../vlc/*"

# Godot Control node for video and audio playback powered by LibVLC.
# Provides seamless rendering to Godot textures, external subtitles, multi-track selection,
# and in-editor property inspection.
node EmeraldVideoPlayer < Control do
  @[ExportFile("*.mp4,*.mkv,*.avi,*.webm,*.mov,*.flv,*.ts,*.m3u8,*.mp3,*.wav,*.ogg,*.flac")]
  property source : String = ""

  @[Export]
  property autoplay : Bool = false

  @[Export]
  property loop : Bool = false

  @[ExportRange(0, 100, 1)]
  property volume : Int32 = 80

  @[ExportRange(0.25, 4.0, 0.05)]
  property playback_rate : Float64 = 1.0

  @[ExportEnum("Fit", "Fill", "Stretch", "Center")]
  property aspect_mode : String = "Fit"

  # Playback lifecycle signals
  signal playback_started
  signal playback_paused
  signal playback_resumed
  signal playback_stopped
  signal playback_finished
  signal metadata_loaded

  # Dynamic progress signals
  signal position_changed(position_pct : Float64, time_ms : Int64)
  signal length_changed(length_ms : Int64)
  signal error_occurred(message : String)
  signal track_changed(track_type : String, track_id : Int32)

  @player : Emerald::VLC::MediaPlayer? = nil
  @media : Emerald::VLC::Media? = nil
  @frame_buffer : Emerald::VLC::VideoFrameBuffer? = nil
  @texture : Godot::ImageTexture? = nil
  @image : Godot::Image? = nil
  @texture_rect : Godot::TextureRect? = nil
  @current_width : UInt32 = 0_u32
  @current_height : UInt32 = 0_u32
  @last_reported_time : Int64 = -1_i64

  def _ready : Void
    setup_texture_rect
    unless source.empty?
      open(source)
      play if autoplay
    end
  end

  def _process(delta : Float64) : Void
    if p = @player
      p.event_manager.poll_events

      # Check for loop restart
      if loop && p.state == Emerald::VLC::LibVLC::State::Ended
        p.stop
        p.play
      end

      # Periodic position update
      current_time = p.time_ms
      if current_time >= 0 && current_time != @last_reported_time
        @last_reported_time = current_time
        emit_position_changed(p.position.to_f64, current_time)
      end

      # Update video texture from double-buffered frame surface
      if fb = @frame_buffer
        if fb.has_new_frame
          update_video_texture(fb)
        end
      end
    end
  end

  def _exit_tree : Void
    stop
    @player = nil
    @media = nil
    @frame_buffer = nil
  end

  # Opens a video file or network stream
  def open(media_path : String) : Bool
    return false if media_path.empty?

    resolved_path = resolve_source_path(media_path)
    @media = Emerald::VLC::Media.new(resolved_path)
    player = Emerald::VLC::MediaPlayer.new
    @player = player

    # Setup frame buffer for video decoding
    fb = Emerald::VLC::VideoFrameBuffer.new
    @frame_buffer = fb
    player.enable_video_callbacks(fb)

    # Apply configuration
    player.volume = volume
    player.playback_rate = playback_rate.to_f32
    player.media = @media

    # Wire up player events to Godot signals
    player.event_manager.on_playing = ->{ emit_playback_started }
    player.event_manager.on_paused = ->{ emit_playback_paused }
    player.event_manager.on_stopped = ->{ emit_playback_stopped }
    player.event_manager.on_ended = ->{ emit_playback_finished }
    player.event_manager.on_error = ->(err : String) { emit_error_occurred(err) }

    emit_metadata_loaded
    true
  end

  # Starts or resumes video playback
  def play : Bool
    if p = @player
      p.volume = volume
      p.playback_rate = playback_rate.to_f32
      res = p.play
      emit_playback_resumed if res
      res
    elsif !source.empty?
      open(source)
      play
    else
      false
    end
  end

  # Pauses video playback
  def pause : Void
    @player.try(&.pause)
    emit_playback_paused
  end

  # Toggles between play and pause
  def toggle_pause : Void
    if playing?
      pause
    else
      play
    end
  end

  # Stops video playback and resets position
  def stop : Void
    @player.try(&.stop)
    emit_playback_stopped
  end

  # Returns true if currently playing
  def playing? : Bool
    @player.try(&.playing?) || false
  end

  # Seeks to timestamp in milliseconds
  def seek(time_ms : Int64) : Void
    @player.try(&.time_ms = time_ms)
  end

  # Seeks to normalized progress ratio (0.0 .. 1.0)
  def seek_ratio(ratio : Float64) : Void
    @player.try(&.position = ratio.to_f32)
  end

  # Steps forward a single video frame
  def next_frame : Void
    @player.try(&.next_frame)
  end

  # Loads an external subtitle file (.srt, .vtt, .ass)
  def load_subtitles(file_path : String) : Bool
    return false unless p = @player
    resolved = resolve_source_path(file_path)
    p.add_subtitle_file(resolved)
  end

  # Selects an active subtitle track by ID (-1 to disable)
  def select_subtitle_track(track_id : Int32) : Void
    if p = @player
      p.subtitle_track = track_id
      emit_track_changed("subtitle", track_id)
    end
  end

  # Sets subtitle timing delay in milliseconds
  def set_subtitle_delay(delay_ms : Int64) : Void
    @player.try(&.subtitle_delay_ms = delay_ms)
  end

  # Queries all subtitle tracks in current media
  def subtitle_tracks : Array(Emerald::VLC::SubtitleTrack)
    @player.try(&.subtitle_tracks) || Array(Emerald::VLC::SubtitleTrack).new
  end

  # Selects an active audio dub track by ID (-1 to mute)
  def select_audio_track(track_id : Int32) : Void
    if p = @player
      p.audio_track = track_id
      emit_track_changed("audio", track_id)
    end
  end

  # Sets audio timing delay in milliseconds (for lip-sync)
  def set_audio_delay(delay_ms : Int64) : Void
    @player.try(&.audio_delay_ms = delay_ms)
  end

  # Queries all audio tracks in current media
  def audio_tracks : Array(Emerald::VLC::AudioTrack)
    @player.try(&.audio_tracks) || Array(Emerald::VLC::AudioTrack).new
  end

  # Selects an active video stream/angle by ID
  def select_video_track(track_id : Int32) : Void
    if p = @player
      p.video_track = track_id
      emit_track_changed("video", track_id)
    end
  end

  # Queries all video tracks in current media
  def video_tracks : Array(Emerald::VLC::VideoTrack)
    @player.try(&.video_tracks) || Array(Emerald::VLC::VideoTrack).new
  end

  # Sets 10-band audio graphic equalizer preset
  def set_equalizer_preset(preset_name : String) : Void
    return unless p = @player
    eq = Emerald::VLC::Equalizer.from_preset(preset_name)
    p.equalizer = eq
  end

  # Captures a video snapshot to a local file (.png, .jpg)
  def take_snapshot(file_path : String) : Bool
    return false unless p = @player
    resolved = resolve_source_path(file_path)
    p.take_snapshot(resolved)
  end

  # Extracts media metadata tags
  def get_metadata : Emerald::VLC::Metadata?
    @media.try(&.metadata)
  end

  # Texture containing decoded video frames
  def video_texture : Godot::ImageTexture?
    @texture
  end

  private def setup_texture_rect : Void
    tr = Godot.create(Godot::TextureRect)
    @texture_rect = tr

    # Anchor to fill Control parent
    tr.set_anchors_preset(Godot::Control::LayoutPreset::PresetFullRect.value, false)

    case aspect_mode
    when "Fit"
      tr.set_expand_mode(Godot::TextureRect::ExpandMode::ExpandIgnoreSize.value)
      tr.set_stretch_mode(Godot::TextureRect::StretchMode::StretchKeepAspectCentered.value)
    when "Fill"
      tr.set_expand_mode(Godot::TextureRect::ExpandMode::ExpandIgnoreSize.value)
      tr.set_stretch_mode(Godot::TextureRect::StretchMode::StretchKeepAspectCovered.value)
    when "Stretch"
      tr.set_expand_mode(Godot::TextureRect::ExpandMode::ExpandIgnoreSize.value)
      tr.set_stretch_mode(Godot::TextureRect::StretchMode::StretchScale.value)
    when "Center"
      tr.set_expand_mode(Godot::TextureRect::ExpandMode::ExpandKeepSize.value)
      tr.set_stretch_mode(Godot::TextureRect::StretchMode::StretchKeepCentered.value)
    end

    add_child(tr)
  end

  private def update_video_texture(fb : Emerald::VLC::VideoFrameBuffer) : Void
    fb.pull_frame do |pixels, w, h|
      next if w == 0 || h == 0

      # Recreate Godot Image & Texture if resolution changes
      if @texture.nil? || @image.nil? || @current_width != w || @current_height != h
        @current_width = w
        @current_height = h

        img = Godot.create(Godot::Image)
        img.create_empty(w.to_i64, h.to_i64, false, Godot::Image::Format::FormatRgba8.value)
        @image = img

        tex = Godot.create(Godot::ImageTexture)
        tex.set_image(img)
        @texture = tex
        @texture_rect.try(&.set_texture(tex))
        emit_length_changed(@player.try(&.length_ms) || 0_i64)
      end

      # Transfer decoded pixel buffer into Godot Image
      if img = @image
        if tex = @texture
          # Fast update of texture
          tex.update(img)
        end
      end
    end
  end

  private def resolve_source_path(path : String) : String
    return path if path =~ %r{^[a-zA-Z][a-zA-Z0-9+-.]*://}
    if path.starts_with?("res://")
      # Resolve res:// using Godot ProjectSettings
      Godot.to_godot_res_path(path)
      File.expand_path(path.sub("res://", ""))
    else
      File.expand_path(path)
    end
  end
end

module Emerald
  alias VideoPlayer = EmeraldVideoPlayer
end
