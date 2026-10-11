require "lapis"
require "../vlc/*"

# Godot Node3D for in-world 3D video playback powered by LibVLC.
# Provides an ImageTexture that can be mapped onto 3D surfaces (in-game screens, TVs, cinema displays)
# or rendered automatically via an optional internal Sprite3D.
node EmeraldVideoPlayer3D < Node3D do
  @[Export]
  property media_resource : EmeraldMediaResource? = nil

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

  @[Export]
  property create_sprite3d : Bool = true

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

  @player : Emerald::VLC::MediaPlayer? = nil
  @media : Emerald::VLC::Media? = nil
  @frame_buffer : Emerald::VLC::VideoFrameBuffer? = nil
  @texture : Godot::ImageTexture? = nil
  @image : Godot::Image? = nil
  @sprite3d : Godot::Sprite3D? = nil
  @current_width : UInt32 = 0_u32
  @current_height : UInt32 = 0_u32
  @last_reported_time : Int64 = -1_i64

  def _ready : Void
    ResourceFormatLoaderEmerald.ensure_registered rescue nil

    if create_sprite3d
      s3d = Godot.create(Godot::Sprite3D)
      @sprite3d = s3d
      add_child(s3d)
    end

    target_source = source
    if target_source.empty? && (mr = media_resource)
      target_source = mr.file_path
    end

    unless target_source.empty?
      open(target_source)
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
        position_changed.emit(p.position.to_f64, current_time)
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

    begin
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
      player.event_manager.on_playing = ->{ playback_started.emit; nil }
      player.event_manager.on_paused = ->{ playback_paused.emit; nil }
      player.event_manager.on_stopped = ->{ playback_stopped.emit; nil }
      player.event_manager.on_ended = ->{ playback_finished.emit; nil }
      player.event_manager.on_error = ->(err : String) { error_occurred.emit(err); nil }

      metadata_loaded.emit
      true
    rescue ex
      Godot.printerr("[EmeraldVideoPlayer3D] Failed to open '#{media_path}': #{ex.message}")
      error_occurred.emit(ex.message || "Failed to open media")
      false
    end
  end

  # Starts or resumes video playback
  def play : Bool
    if p = @player
      p.volume = volume
      p.playback_rate = playback_rate.to_f32
      res = p.play
      playback_resumed.emit if res
      res
    elsif !source.empty?
      if open(source)
        play
      else
        false
      end
    else
      false
    end
  end

  # Pauses video playback
  def pause : Void
    @player.try(&.pause)
    playback_paused.emit
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
    playback_stopped.emit
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
    @player.try(&.subtitle_track = track_id)
  end

  # Selects an active audio dub track by ID (-1 to mute)
  def select_audio_track(track_id : Int32) : Void
    @player.try(&.audio_track = track_id)
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

  # Returns the ImageTexture containing live decoded video frames
  def video_texture : Godot::ImageTexture?
    @texture
  end

  private def update_video_texture(fb : Emerald::VLC::VideoFrameBuffer) : Void
    fb.pull_frame do |pixels, w, h|
      next if w == 0 || h == 0 || pixels.size < (w.to_i64 * h.to_i64 * 4_i64)

      # Recreate Godot Image & Texture if resolution changes
      if @texture.nil? || @image.nil? || @current_width != w || @current_height != h
        @current_width = w
        @current_height = h

        img = Godot::Image.create_from_buffer(w.to_i32, h.to_i32, Godot::Image::Format::FormatRgba8, pixels, false)
        @image = img

        tex = Godot::ImageTexture.create_from_image(img)
        @texture = tex

        # Update Sprite3D if present
        @sprite3d.try(&.set_texture(tex))
        length_changed.emit(@player.try(&.length_ms) || 0_i64)
      elsif img = @image
        if tex = @texture
          # Fast-path zero-copy blit from LibVLC pixel buffer into Godot Image
          img.update_buffer(w.to_i32, h.to_i32, Godot::Image::Format::FormatRgba8, pixels, false)
          tex.update(img) rescue nil
        end
      end
    end
  end

  private def resolve_source_path(path : String) : String
    Emerald.resolve_source_path(path)
  end
end

module Emerald
  alias VideoPlayer3D = EmeraldVideoPlayer3D
end
