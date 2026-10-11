module Emerald
  module VLC
    # High-level media player wrapper controlling playback, tracks, subtitles, and video rendering.
    class MediaPlayer
      getter handle : LibVLC::MediaPlayer
      getter instance : Instance
      getter media : Media?
      getter frame_buffer : VideoFrameBuffer?
      getter event_manager : EventManager

      # Boxed wrapper passed to C callbacks
      class RenderContext
        property player : MediaPlayer
        property frame_buffer : VideoFrameBuffer

        def initialize(@player : MediaPlayer, @frame_buffer : VideoFrameBuffer)
        end
      end

      @render_context : RenderContext?
      @render_context_box : Void* = Pointer(Void).null

      def initialize(instance : Instance? = nil)
        @instance = instance || Instance.default
        @handle = LibVLC.libvlc_media_player_new(@instance.handle)

        if @handle.null?
          raise "Failed to create LibVLC MediaPlayer"
        end

        ev_handle = LibVLC.libvlc_media_player_event_manager(@handle)
        @event_manager = EventManager.new(ev_handle)
      end

      def self.from_media(media : Media) : MediaPlayer
        player = new(media.instance)
        player.media = media
        player
      end

      # Assigns a new media source to the player
      def media=(media : Media?) : Media?
        @media = media
        if media
          LibVLC.libvlc_media_player_set_media(@handle, media.handle)
        end
        media
      end

      # Starts playback
      def play : Bool
        res = LibVLC.libvlc_media_player_play(@handle)
        res == 0
      end

      # Pauses playback
      def pause : Nil
        LibVLC.libvlc_media_player_pause(@handle)
      end

      # Toggles between play and pause
      def toggle_pause : Nil
        if playing?
          pause
        else
          play
        end
      end

      # Stops playback
      def stop : Nil
        LibVLC.libvlc_media_player_stop(@handle)
      end

      # Returns true if currently playing
      def playing? : Bool
        LibVLC.libvlc_media_player_is_playing(@handle) != 0
      end

      # Current playback state
      def state : LibVLC::State
        LibVLC.libvlc_media_player_get_state(@handle)
      end

      # Media duration in milliseconds
      def length_ms : Int64
        LibVLC.libvlc_media_player_get_length(@handle)
      end

      # Current playback position in milliseconds
      def time_ms : Int64
        LibVLC.libvlc_media_player_get_time(@handle)
      end

      # Seeks to timestamp in milliseconds
      def time_ms=(new_time_ms : Int64) : Int64
        LibVLC.libvlc_media_player_set_time(@handle, new_time_ms)
        new_time_ms
      end

      # Current playback position as normalized ratio (0.0 .. 1.0)
      def position : Float32
        LibVLC.libvlc_media_player_get_position(@handle)
      end

      # Seeks to normalized ratio (0.0 .. 1.0)
      def position=(pos : Float32) : Float32
        clamped = pos.clamp(0.0_f32, 1.0_f32)
        LibVLC.libvlc_media_player_set_position(@handle, clamped)
        clamped
      end

      # Playback speed rate multiplier (e.g. 1.0 = normal, 2.0 = double speed)
      def playback_rate : Float32
        LibVLC.libvlc_media_player_get_rate(@handle)
      end

      # Sets playback speed rate multiplier (0.25 .. 4.0)
      def playback_rate=(rate : Float32) : Float32
        clamped = rate.clamp(0.25_f32, 4.0_f32)
        LibVLC.libvlc_media_player_set_rate(@handle, clamped)
        clamped
      end

      # Steps forward by a single video frame
      def next_frame : Nil
        LibVLC.libvlc_media_player_next_frame(@handle)
      end

      # True if seeking is supported by the media/stream
      def seekable? : Bool
        LibVLC.libvlc_media_player_is_seekable(@handle) != 0
      end

      # True if pause is supported
      def can_pause? : Bool
        LibVLC.libvlc_media_player_can_pause(@handle) != 0
      end

      # Audio Volume (0 .. 100/200)
      def volume : Int32
        LibVLC.libvlc_audio_get_volume(@handle)
      end

      def volume=(vol : Int32) : Int32
        clamped = vol.clamp(0, 200)
        LibVLC.libvlc_audio_set_volume(@handle, clamped)
        clamped
      end

      # Audio Mute state
      def mute? : Bool
        LibVLC.libvlc_audio_get_mute(@handle) > 0
      end

      def mute=(muted : Bool) : Bool
        LibVLC.libvlc_audio_set_mute(@handle, muted ? 1 : 0)
        muted
      end

      def toggle_mute : Nil
        LibVLC.libvlc_audio_toggle_mute(@handle)
      end

      # Audio delay in milliseconds (for lip-sync correction)
      def audio_delay_ms : Int64
        LibVLC.libvlc_audio_get_delay(@handle) // 1000
      end

      def audio_delay_ms=(delay : Int64) : Int64
        LibVLC.libvlc_audio_set_delay(@handle, delay * 1000)
        delay
      end

      # Audio output channel mode (Stereo, Reverse Stereo, Dolby, etc.)
      def audio_channel : LibVLC::AudioOutputChannel
        LibVLC.libvlc_audio_get_channel(@handle)
      end

      def audio_channel=(ch : LibVLC::AudioOutputChannel) : LibVLC::AudioOutputChannel
        LibVLC.libvlc_audio_set_channel(@handle, ch)
        ch
      end

      # Available audio tracks
      def audio_tracks : Array(AudioTrack)
        read_tracks_list do
          LibVLC.libvlc_audio_get_track_description(@handle)
        end.map { |id, name| AudioTrack.new(id: id, name: name) }
      end

      # Currently active audio track ID (-1 if disabled)
      def current_audio_track : Int32
        LibVLC.libvlc_audio_get_track(@handle)
      end

      def audio_track=(track_id : Int32) : Int32
        LibVLC.libvlc_audio_set_track(@handle, track_id)
        track_id
      end

      # Applies an audio graphic equalizer
      def equalizer=(eq : Equalizer?) : Nil
        if eq
          LibVLC.libvlc_media_player_set_equalizer(@handle, eq.handle)
        else
          LibVLC.libvlc_media_player_set_equalizer(@handle, Pointer(Void).null.as(LibVLC::Equalizer))
        end
      end

      # Subtitle / SPU tracks
      def subtitle_tracks : Array(SubtitleTrack)
        read_tracks_list do
          LibVLC.libvlc_video_get_spu_description(@handle)
        end.map { |id, name| SubtitleTrack.new(id: id, name: name) }
      end

      # Currently active subtitle track ID (-1 if disabled)
      def current_subtitle_track : Int32
        LibVLC.libvlc_video_get_spu(@handle)
      end

      def subtitle_track=(track_id : Int32) : Int32
        LibVLC.libvlc_video_set_spu(@handle, track_id)
        track_id
      end

      # Loads an external subtitle file (.srt, .vtt, .sub, .ass)
      def add_subtitle_file(file_path : String) : Bool
        expanded = File.expand_path(file_path)
        res = LibVLC.libvlc_video_set_subtitle_file(@handle, expanded)
        res != 0
      end

      # Subtitle delay in milliseconds
      def subtitle_delay_ms : Int64
        LibVLC.libvlc_video_get_spu_delay(@handle) // 1000
      end

      def subtitle_delay_ms=(delay : Int64) : Int64
        LibVLC.libvlc_video_set_spu_delay(@handle, delay * 1000)
        delay
      end

      # Video tracks
      def video_tracks : Array(VideoTrack)
        read_tracks_list do
          LibVLC.libvlc_video_get_track_description(@handle)
        end.map { |id, name| VideoTrack.new(id: id, name: name) }
      end

      def current_video_track : Int32
        LibVLC.libvlc_video_get_track(@handle)
      end

      def video_track=(track_id : Int32) : Int32
        LibVLC.libvlc_video_set_track(@handle, track_id)
        track_id
      end

      # Video aspect ratio string (e.g. "16:9", "4:3")
      def aspect_ratio : String?
        ptr = LibVLC.libvlc_video_get_aspect_ratio(@handle)
        return nil if ptr.null?
        String.new(ptr)
      end

      def aspect_ratio=(ratio : String) : String
        LibVLC.libvlc_video_set_aspect_ratio(@handle, ratio)
        ratio
      end

      # Captures a video snapshot to a local file (.png, .jpg)
      def take_snapshot(file_path : String, width : UInt32 = 0_u32, height : UInt32 = 0_u32) : Bool
        expanded = File.expand_path(file_path)
        res = LibVLC.libvlc_video_take_snapshot(@handle, 0_u32, expanded, width, height)
        res == 0
      end

      # Gets current video width and height in pixels
      def video_size : Tuple(UInt32, UInt32)
        px = 0_u32
        py = 0_u32
        res = LibVLC.libvlc_video_get_size(@handle, 0_u32, pointerof(px), pointerof(py))
        if res == 0
          {px, py}
        else
          {0_u32, 0_u32}
        end
      end

      # Enables memory video decoding using double-buffered frame surface
      def enable_video_callbacks(frame_buffer : VideoFrameBuffer) : Nil
        @frame_buffer = frame_buffer
        ctx = RenderContext.new(self, frame_buffer)
        @render_context = ctx
        @render_context_box = Box.box(ctx)

        lock_cb = ->(opaque : Void*, planes : Void**) {
          c = Box(RenderContext).unbox(opaque)
          planes[0] = c.frame_buffer.lock_write_buffer.as(Void*)
          Pointer(Void).null
        }

        unlock_cb = ->(opaque : Void*, picture : Void*, planes : Void**) {
          c = Box(RenderContext).unbox(opaque)
          c.frame_buffer.unlock_and_swap
          nil
        }

        display_cb = ->(opaque : Void*, picture : Void*) {
          nil
        }

        setup_cb = ->(
          opaque_ptr : Void**,
          chroma : LibC::Char*,
          width : LibC::UInt*,
          height : LibC::UInt*,
          pitches : LibC::UInt*,
          lines : LibC::UInt*
        ) {
          chroma[0] = 'R'.ord.to_u8
          chroma[1] = 'G'.ord.to_u8
          chroma[2] = 'B'.ord.to_u8
          chroma[3] = 'A'.ord.to_u8

          w = width.value
          h = height.value

          pitches[0] = w * 4_u32
          lines[0] = h

          c = Box(RenderContext).unbox(opaque_ptr.value)
          c.frame_buffer.resize(w, h)
          1_u32 # 1 video plane
        }

        cleanup_cb = ->(opaque : Void*) {
          nil
        }

        LibVLC.libvlc_video_set_format_callbacks(@handle, setup_cb, cleanup_cb)
        LibVLC.libvlc_video_set_callbacks(@handle, lock_cb, unlock_cb, display_cb, @render_context_box)
      end

      # Helper to traverse TrackDescription linked lists
      private def read_tracks_list(&block : -> LibVLC::TrackDescription*) : Array(Tuple(Int32, String))
        result = Array(Tuple(Int32, String)).new
        head = block.call
        return result if head.null?

        curr = head
        while !curr.null?
          desc = curr.value
          name = desc.name.null? ? "Track #{desc.id}" : String.new(desc.name)
          result << {desc.id.to_i32, name}
          curr = desc.next
        end

        LibVLC.libvlc_track_description_list_release(head)
        result
      end

      def finalize
        unless @handle.null?
          LibVLC.libvlc_media_player_stop(@handle)
          LibVLC.libvlc_media_player_release(@handle)
          @handle = Pointer(Void).null.as(LibVLC::MediaPlayer)
        end
      end
    end
  end
end
