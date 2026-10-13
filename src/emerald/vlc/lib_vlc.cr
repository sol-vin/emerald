module Emerald
  module VLC
    {% if flag?(:windows) %}
      @[Link(ldflags: "#{__DIR__}/../../../ext/libvlc/libvlc.lib")]
    {% else %}
      @[Link("vlc")]
    {% end %}
    lib LibVLC
      # Opaque pointer handles
      type Instance = Void*
      type Media = Void*
      type MediaPlayer = Void*
      type EventManager = Void*
      type Equalizer = Void*

      # Playback states
      enum State : LibC::Int
        NothingSpecial = 0
        Opening        = 1
        Buffering      = 2
        Playing        = 3
        Paused         = 4
        Stopped        = 5
        Ended          = 6
        Error          = 7
      end

      # Metadata fields
      enum Meta : LibC::Int
        Title       = 0
        Artist      = 1
        Genre       = 2
        Copyright   = 3
        Album       = 4
        TrackNumber = 5
        Description = 6
        Rating      = 7
        Date        = 8
        Setting     = 9
        URL         = 10
        Language    = 11
        NowPlaying  = 12
        Publisher   = 13
        EncodedBy   = 14
        ArtworkURL  = 15
        TrackID     = 16
        TrackTotal  = 17
        Director    = 18
        Season      = 19
        Episode     = 20
        ShowName    = 21
        Actors      = 22
        AlbumArtist = 23
        DiscNumber  = 24
        DiscTotal   = 25
      end

      # Track types
      enum TrackType : LibC::Int
        Unknown = -1
        Audio   = 0
        Video   = 1
        Text    = 2
      end

      # Media parse flags
      enum MediaParseFlag : LibC::Int
        ParseLocal   = 0x00
        ParseNetwork = 0x01
        FetchLocal   = 0x02
        FetchNetwork = 0x04
        DoInteract   = 0x08
      end

      # Media slave types (for subtitles / alternate audio)
      enum MediaSlaveType : LibC::Int
        Subtitle = 0
        Audio    = 1
      end

      # Audio channel modes
      enum AudioOutputChannel : LibC::Int
        Error   = -1
        Unset   = 0
        Stereo  = 1
        RStereo = 2
        Left    = 3
        Right   = 4
        Dolbys  = 5
      end

      # Track description node (linked list)
      struct TrackDescription
        id : LibC::Int
        name : LibC::Char*
        next : TrackDescription*
      end

      # Media track details
      struct AudioTrack
        channels : LibC::UInt
        rate : LibC::UInt
      end

      struct VideoTrack
        height : LibC::UInt
        width : LibC::UInt
        sar_num : LibC::UInt
        sar_den : LibC::UInt
        frame_rate_num : LibC::UInt
        frame_rate_den : LibC::UInt
        orientation : LibC::Int
        projection : LibC::Int
        pose : StaticArray(Float32, 4)
      end

      struct SubtitleTrack
        encoding : LibC::Char*
      end

      union TrackUnion
        audio : AudioTrack
        video : VideoTrack
        subtitle : SubtitleTrack
      end

      struct MediaTrack
        codec : UInt32
        original_fourcc : UInt32
        id : LibC::Int
        track_type : TrackType
        profile : LibC::Int
        level : LibC::Int
        u : TrackUnion
        bitrate : LibC::UInt
        language : LibC::Char*
        description : LibC::Char*
      end

      # Video memory render callbacks
      alias VideoLockCallback = (Void*, Void**) -> Void*
      alias VideoUnlockCallback = (Void*, Void*, Void**) -> Void
      alias VideoDisplayCallback = (Void*, Void*) -> Void
      alias VideoFormatCallback = (Void**, LibC::Char*, LibC::UInt*, LibC::UInt*, LibC::UInt*, LibC::UInt*) -> LibC::UInt
      alias VideoCleanupCallback = (Void*) -> Void

      # Audio memory callbacks
      alias AudioPlayCallback = (Void*, Void*, LibC::UInt, Int64) -> Void
      alias AudioPauseCallback = (Void*, Int64) -> Void
      alias AudioResumeCallback = (Void*, Int64) -> Void
      alias AudioFlushCallback = (Void*, Int64) -> Void
      alias AudioDrainCallback = (Void*) -> Void
      alias AudioSetVolumeCallback = (Void*, Float32, Bool) -> Void

      # LibVLC Event structures
      enum EventType : LibC::Int
        MediaMetaChanged           = 0
        MediaSubItemAdded          = 1
        MediaDurationChanged       = 2
        MediaParsedChanged         = 3
        MediaFreed                 = 4
        MediaStateChanged          = 5
        MediaSubItemTreeAdded      = 6

        MediaPlayerMediaChanged     = 0x100
        MediaPlayerNothingSpecial   = 0x101
        MediaPlayerOpening          = 0x102
        MediaPlayerBuffering        = 0x103
        MediaPlayerPlaying          = 0x104
        MediaPlayerPaused           = 0x105
        MediaPlayerStopped          = 0x106
        MediaPlayerForward          = 0x107
        MediaPlayerBackward         = 0x108
        MediaPlayerEndReached       = 0x109
        MediaPlayerEncounteredError = 0x10a
        MediaPlayerTimeChanged      = 0x10b
        MediaPlayerPositionChanged  = 0x10c
        MediaPlayerSeekableChanged  = 0x10d
        MediaPlayerPausableChanged  = 0x10e
        MediaPlayerTitleChanged     = 0x10f
        MediaPlayerSnapshotTaken    = 0x110
        MediaPlayerLengthChanged    = 0x111
        MediaPlayerVout             = 0x112
        MediaPlayerScrambledChanged = 0x113
        MediaPlayerESAdded          = 0x114
        MediaPlayerESDeleted        = 0x115
        MediaPlayerESSelected       = 0x116
        MediaPlayerAudioVolume      = 0x117
        MediaPlayerAudioMuted       = 0x118
        MediaPlayerAudioDevice      = 0x119
        MediaPlayerChapterChanged   = 0x11a
      end

      struct EventUnion
        padding : StaticArray(UInt64, 8)
      end

      struct Event
        type : EventType
        obj : Void*
        u : EventUnion
      end

      alias EventCallback = (Event*, Void*) -> Void

      # Core functions
      fun libvlc_get_version : LibC::Char*
      fun libvlc_get_compiler : LibC::Char*
      fun libvlc_get_changeset : LibC::Char*
      fun libvlc_new(argc : LibC::Int, argv : LibC::Char**) : Instance
      fun libvlc_release(instance : Instance) : Void
      fun libvlc_retain(instance : Instance) : Void
      fun libvlc_set_user_agent(instance : Instance, name : LibC::Char*, http : LibC::Char*) : Void
      fun libvlc_set_app_id(instance : Instance, id : LibC::Char*, version : LibC::Char*, icon : LibC::Char*) : Void
      fun libvlc_errmsg : LibC::Char*
      fun libvlc_clearerr : Void

      # Media functions
      fun libvlc_media_new_path(instance : Instance, path : LibC::Char*) : Media
      fun libvlc_media_new_location(instance : Instance, mrl : LibC::Char*) : Media
      fun libvlc_media_new_fd(instance : Instance, fd : LibC::Int) : Media
      fun libvlc_media_release(media : Media) : Void
      fun libvlc_media_retain(media : Media) : Void
      fun libvlc_media_get_mrl(media : Media) : LibC::Char*
      fun libvlc_media_get_duration(media : Media) : Int64
      fun libvlc_media_get_state(media : Media) : State
      fun libvlc_media_parse(media : Media) : Void
      fun libvlc_media_parse_with_options(media : Media, flags : MediaParseFlag, timeout : LibC::Int) : LibC::Int
      fun libvlc_media_get_meta(media : Media, meta : Meta) : LibC::Char*
      fun libvlc_media_set_meta(media : Media, meta : Meta, value : LibC::Char*) : Void
      fun libvlc_media_save_meta(media : Media) : LibC::Int
      fun libvlc_media_tracks_get(media : Media, tracks : MediaTrack***) : LibC::UInt
      fun libvlc_media_tracks_release(tracks : MediaTrack**, count : LibC::UInt) : Void
      fun libvlc_media_slaves_add(media : Media, slave_type : MediaSlaveType, priority : LibC::UInt, uri : LibC::Char*) : LibC::Int
      fun libvlc_media_add_option(media : Media, options : LibC::Char*) : Void
      fun libvlc_media_add_option_flag(media : Media, options : LibC::Char*, flags : LibC::UInt) : Void

      # Media Player functions
      fun libvlc_media_player_new(instance : Instance) : MediaPlayer
      fun libvlc_media_player_new_from_media(media : Media) : MediaPlayer
      fun libvlc_media_player_release(player : MediaPlayer) : Void
      fun libvlc_media_player_retain(player : MediaPlayer) : Void
      fun libvlc_media_player_set_media(player : MediaPlayer, media : Media) : Void
      fun libvlc_media_player_get_media(player : MediaPlayer) : Media
      fun libvlc_media_player_play(player : MediaPlayer) : LibC::Int
      fun libvlc_media_player_pause(player : MediaPlayer) : Void
      fun libvlc_media_player_set_pause(player : MediaPlayer, do_pause : LibC::Int) : Void
      fun libvlc_media_player_stop(player : MediaPlayer) : Void
      fun libvlc_media_player_is_playing(player : MediaPlayer) : LibC::Int
      fun libvlc_media_player_get_state(player : MediaPlayer) : State
      fun libvlc_media_player_get_length(player : MediaPlayer) : Int64
      fun libvlc_media_player_get_time(player : MediaPlayer) : Int64
      fun libvlc_media_player_set_time(player : MediaPlayer, time_ms : Int64) : Void
      fun libvlc_media_player_get_position(player : MediaPlayer) : Float32
      fun libvlc_media_player_set_position(player : MediaPlayer, pos : Float32) : Void
      fun libvlc_media_player_get_rate(player : MediaPlayer) : Float32
      fun libvlc_media_player_set_rate(player : MediaPlayer, rate : Float32) : LibC::Int
      fun libvlc_media_player_is_seekable(player : MediaPlayer) : LibC::Int
      fun libvlc_media_player_can_pause(player : MediaPlayer) : LibC::Int
      fun libvlc_media_player_next_frame(player : MediaPlayer) : Void
      fun libvlc_media_player_has_vout(player : MediaPlayer) : LibC::UInt

      # Video memory render & controls
      fun libvlc_video_set_callbacks(
        player : MediaPlayer,
        lock : VideoLockCallback,
        unlock : VideoUnlockCallback,
        display : VideoDisplayCallback,
        opaque : Void*
      ) : Void
      fun libvlc_video_set_format(
        player : MediaPlayer,
        chroma : LibC::Char*,
        width : LibC::UInt,
        height : LibC::UInt,
        pitch : LibC::UInt
      ) : Void
      fun libvlc_video_set_format_callbacks(
        player : MediaPlayer,
        setup : VideoFormatCallback,
        cleanup : VideoCleanupCallback
      ) : Void
      fun libvlc_video_get_size(player : MediaPlayer, num : LibC::UInt, px : LibC::UInt*, py : LibC::UInt*) : LibC::Int
      fun libvlc_video_get_cursor(player : MediaPlayer, num : LibC::UInt, px : LibC::Int*, py : LibC::Int*) : LibC::Int
      fun libvlc_video_set_mouse_input(player : MediaPlayer, enable : LibC::UInt) : Void
      fun libvlc_video_set_key_input(player : MediaPlayer, enable : LibC::UInt) : Void
      fun libvlc_video_get_scale(player : MediaPlayer) : Float32
      fun libvlc_video_set_scale(player : MediaPlayer, factor : Float32) : Void
      fun libvlc_video_get_aspect_ratio(player : MediaPlayer) : LibC::Char*
      fun libvlc_video_set_aspect_ratio(player : MediaPlayer, aspect : LibC::Char*) : Void
      fun libvlc_video_get_spu(player : MediaPlayer) : LibC::Int
      fun libvlc_video_set_spu(player : MediaPlayer, spu : LibC::Int) : LibC::Int
      fun libvlc_video_get_spu_count(player : MediaPlayer) : LibC::Int
      fun libvlc_video_get_spu_description(player : MediaPlayer) : TrackDescription*
      fun libvlc_video_set_subtitle_file(player : MediaPlayer, subtitle : LibC::Char*) : LibC::Int
      fun libvlc_video_get_spu_delay(player : MediaPlayer) : Int64
      fun libvlc_video_set_spu_delay(player : MediaPlayer, delay : Int64) : LibC::Int
      fun libvlc_video_get_track_count(player : MediaPlayer) : LibC::Int
      fun libvlc_video_get_track(player : MediaPlayer) : LibC::Int
      fun libvlc_video_set_track(player : MediaPlayer, track : LibC::Int) : LibC::Int
      fun libvlc_video_get_track_description(player : MediaPlayer) : TrackDescription*
      fun libvlc_video_take_snapshot(player : MediaPlayer, num : LibC::UInt, filepath : LibC::Char*, width : LibC::UInt, height : LibC::UInt) : LibC::Int

      # Audio controls & equalizer
      fun libvlc_audio_get_volume(player : MediaPlayer) : LibC::Int
      fun libvlc_audio_set_volume(player : MediaPlayer, volume : LibC::Int) : LibC::Int
      fun libvlc_audio_get_mute(player : MediaPlayer) : LibC::Int
      fun libvlc_audio_set_mute(player : MediaPlayer, status : LibC::Int) : Void
      fun libvlc_audio_toggle_mute(player : MediaPlayer) : Void
      fun libvlc_audio_get_track_count(player : MediaPlayer) : LibC::Int
      fun libvlc_audio_get_track(player : MediaPlayer) : LibC::Int
      fun libvlc_audio_set_track(player : MediaPlayer, track : LibC::Int) : LibC::Int
      fun libvlc_audio_get_track_description(player : MediaPlayer) : TrackDescription*
      fun libvlc_audio_get_channel(player : MediaPlayer) : AudioOutputChannel
      fun libvlc_audio_set_channel(player : MediaPlayer, channel : AudioOutputChannel) : LibC::Int
      fun libvlc_audio_get_delay(player : MediaPlayer) : Int64
      fun libvlc_audio_set_delay(player : MediaPlayer, delay : Int64) : LibC::Int
      fun libvlc_audio_set_callbacks(
        player : MediaPlayer,
        play : AudioPlayCallback,
        pause : AudioPauseCallback,
        resume : AudioResumeCallback,
        flush : AudioFlushCallback,
        drain : AudioDrainCallback,
        opaque : Void*
      ) : Void

      # Audio Equalizer
      fun libvlc_audio_equalizer_new : Equalizer
      fun libvlc_audio_equalizer_new_from_preset(preset : LibC::UInt) : Equalizer
      fun libvlc_audio_equalizer_release(equalizer : Equalizer) : Void
      fun libvlc_audio_equalizer_get_preset_count : LibC::UInt
      fun libvlc_audio_equalizer_get_preset_name(index : LibC::UInt) : LibC::Char*
      fun libvlc_audio_equalizer_get_band_count : LibC::UInt
      fun libvlc_audio_equalizer_get_band_frequency(index : LibC::UInt) : Float32
      fun libvlc_audio_equalizer_get_amp_at_index(equalizer : Equalizer, band : LibC::UInt) : Float32
      fun libvlc_audio_equalizer_set_amp_at_index(equalizer : Equalizer, amp : Float32, band : LibC::UInt) : LibC::Int
      fun libvlc_audio_equalizer_get_preamp(equalizer : Equalizer) : Float32
      fun libvlc_audio_equalizer_set_preamp(equalizer : Equalizer, preamp : Float32) : LibC::Int
      fun libvlc_media_player_set_equalizer(player : MediaPlayer, equalizer : Equalizer) : LibC::Int

      # Track Description list release
      fun libvlc_track_description_list_release(list : TrackDescription*) : Void

      # Event Manager functions
      fun libvlc_media_player_event_manager(player : MediaPlayer) : EventManager
      fun libvlc_media_event_manager(media : Media) : EventManager
      fun libvlc_event_attach(
        manager : EventManager,
        event_type : EventType,
        callback : EventCallback,
        user_data : Void*
      ) : LibC::Int
      fun libvlc_event_detach(
        manager : EventManager,
        event_type : EventType,
        callback : EventCallback,
        user_data : Void*
      ) : Void
    end
  end
end
