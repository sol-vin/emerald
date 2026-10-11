require "lapis"
require "../vlc/*"

# Godot Node for pure audio playback powered by LibVLC.
# Supports local audio files (MP3, FLAC, WAV, OGG, M4A) and streaming audio (Internet Radio, Shoutcast, Icecast, HTTP streams).
node EmeraldAudioPlayer < Node do
  @[ExportFile("*.mp3,*.wav,*.ogg,*.flac,*.m4a,*.aac,*.opus,*.wma")]
  property source : String = ""

  @[Export]
  property autoplay : Bool = false

  @[Export]
  property loop : Bool = false

  @[ExportRange(0, 100, 1)]
  property volume : Int32 = 80

  @[ExportRange(0.25, 4.0, 0.05)]
  property playback_rate : Float64 = 1.0

  @[ExportEnum("None", "Flat", "Rock", "Pop", "Jazz", "Classical", "Club", "Dance", "FullBass", "Headphones", "Party", "Techno", "Vocal")]
  property equalizer_preset : String = "None"

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
  @last_reported_time : Int64 = -1_i64

  def _ready : Void
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
    end
  end

  def _exit_tree : Void
    stop
    @player = nil
    @media = nil
  end

  # Opens an audio source (file path or stream URL)
  def open(media_path : String) : Bool
    return false if media_path.empty?

    resolved_path = resolve_source_path(media_path)
    @media = Emerald::VLC::Media.new(resolved_path)
    player = Emerald::VLC::MediaPlayer.new
    @player = player

    # Apply configuration
    player.volume = volume
    player.playback_rate = playback_rate.to_f32
    player.media = @media

    # Apply equalizer preset if specified
    if equalizer_preset != "None"
      set_equalizer_preset(equalizer_preset)
    end

    # Wire up player events to Godot signals
    player.event_manager.on_playing = ->{ emit_playback_started }
    player.event_manager.on_paused = ->{ emit_playback_paused }
    player.event_manager.on_stopped = ->{ emit_playback_stopped }
    player.event_manager.on_ended = ->{ emit_playback_finished }
    player.event_manager.on_error = ->(err : String) { emit_error_occurred(err) }

    emit_metadata_loaded
    true
  end

  # Starts or resumes audio playback
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

  # Pauses audio playback
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

  # Stops playback and resets position
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

  # Mutes or unmutes audio
  def mute=(muted : Bool) : Void
    @player.try(&.mute = muted)
  end

  def mute? : Bool
    @player.try(&.mute?) || false
  end

  # Sets audio volume (0..100)
  def set_volume(new_volume : Int32) : Void
    self.volume = new_volume
    @player.try(&.volume = new_volume)
  end

  # Selects an active audio track by ID
  def select_audio_track(track_id : Int32) : Void
    @player.try(&.audio_track = track_id)
  end

  # Queries all audio tracks
  def audio_tracks : Array(Emerald::VLC::AudioTrack)
    @player.try(&.audio_tracks) || Array(Emerald::VLC::AudioTrack).new
  end

  # Applies an audio graphic equalizer preset
  def set_equalizer_preset(preset_name : String) : Void
    return unless p = @player
    return if preset_name == "None"
    eq = Emerald::VLC::Equalizer.from_preset(preset_name)
    p.equalizer = eq
  end

  # Extracts media metadata tags
  def get_metadata : Emerald::VLC::Metadata?
    @media.try(&.metadata)
  end

  private def resolve_source_path(path : String) : String
    return path if path =~ %r{^[a-zA-Z][a-zA-Z0-9+-.]*://}
    if path.starts_with?("res://")
      Godot.to_godot_res_path(path)
      File.expand_path(path.sub("res://", ""))
    else
      File.expand_path(path)
    end
  end
end

module Emerald
  alias AudioPlayer = EmeraldAudioPlayer
end
