module Emerald
  module VLC
    # Represents a media resource (local file or network stream) with parsing and metadata inspection.
    class Media
      getter handle : LibVLC::Media
      getter instance : Instance
      getter mrl : String

      def initialize(source : String, instance : Instance? = nil)
        @instance = instance || Instance.default

        # Auto-detect if source is a URL/network stream or local file
        if source =~ %r{^[a-zA-Z][a-zA-Z0-9+-.]*://}
          # Normalize file:// URLs or keep streaming protocols (http, https, rtsp, rtmp)
          @mrl = source
          @handle = LibVLC.libvlc_media_new_location(@instance.handle, source)
        else
          # Local file path
          resolved_path = File.expand_path(source)
          @mrl = resolved_path
          @handle = LibVLC.libvlc_media_new_path(@instance.handle, resolved_path)
        end

        if @handle.null?
          raise "Failed to create LibVLC Media for: #{source}"
        end
      end

      # Media duration in milliseconds (-1 if unknown or live stream)
      def duration_ms : Int64
        LibVLC.libvlc_media_get_duration(@handle)
      end

      # Current media parsing/loading state
      def state : LibVLC::State
        LibVLC.libvlc_media_get_state(@handle)
      end

      # Parses metadata and stream tracks with optional timeout
      def parse(timeout_ms : Int32 = 3000) : Bool
        flags = LibVLC::MediaParseFlag::ParseLocal.value |
                LibVLC::MediaParseFlag::ParseNetwork.value |
                LibVLC::MediaParseFlag::FetchLocal.value

        res = LibVLC.libvlc_media_parse_with_options(
          @handle,
          LibVLC::MediaParseFlag.new(flags),
          timeout_ms
        )
        res == 0
      end

      # Extracts comprehensive metadata from media tags
      def metadata : Metadata
        # Ensure media is parsed
        parse(1500) if duration_ms <= 0

        Metadata.new(
          title: get_meta(LibVLC::Meta::Title),
          artist: get_meta(LibVLC::Meta::Artist),
          album: get_meta(LibVLC::Meta::Album),
          genre: get_meta(LibVLC::Meta::Genre),
          date: get_meta(LibVLC::Meta::Date),
          track_number: get_meta(LibVLC::Meta::TrackNumber),
          description: get_meta(LibVLC::Meta::Description),
          rating: get_meta(LibVLC::Meta::Rating),
          copyright: get_meta(LibVLC::Meta::Copyright),
          publisher: get_meta(LibVLC::Meta::Publisher),
          encoded_by: get_meta(LibVLC::Meta::EncodedBy),
          artwork_url: get_meta(LibVLC::Meta::ArtworkURL),
          duration_ms: Math.max(0_i64, duration_ms)
        )
      end

      # Queries all audio tracks embedded in the media
      def audio_tracks : Array(AudioTrack)
        tracks = Array(AudioTrack).new
        each_track do |t|
          if t.track_type == LibVLC::TrackType::Audio
            name = t.description.null? ? "Audio Track #{t.id}" : String.new(t.description)
            lang = t.language.null? ? nil : String.new(t.language)
            tracks << AudioTrack.new(
              id: t.id,
              name: name,
              channels: t.u.audio.channels,
              sample_rate: t.u.audio.rate,
              codec: fourcc_to_s(t.codec),
              language: lang
            )
          end
        end
        tracks
      end

      # Queries all video tracks embedded in the media
      def video_tracks : Array(VideoTrack)
        tracks = Array(VideoTrack).new
        each_track do |t|
          if t.track_type == LibVLC::TrackType::Video
            name = t.description.null? ? "Video Track #{t.id}" : String.new(t.description)
            fps = if t.u.video.frame_rate_den > 0
                    t.u.video.frame_rate_num.to_f64 / t.u.video.frame_rate_den.to_f64
                  else
                    0.0
                  end
            aspect = if t.u.video.sar_den > 0
                       "#{t.u.video.sar_num}:#{t.u.video.sar_den}"
                     else
                       nil
                     end

            tracks << VideoTrack.new(
              id: t.id,
              name: name,
              width: t.u.video.width,
              height: t.u.video.height,
              frame_rate: fps,
              codec: fourcc_to_s(t.codec),
              aspect_ratio: aspect
            )
          end
        end
        tracks
      end

      # Queries all subtitle / closed-caption tracks embedded in the media
      def subtitle_tracks : Array(SubtitleTrack)
        tracks = Array(SubtitleTrack).new
        each_track do |t|
          if t.track_type == LibVLC::TrackType::Text
            name = t.description.null? ? "Subtitle Track #{t.id}" : String.new(t.description)
            lang = t.language.null? ? nil : String.new(t.language)
            enc = t.u.subtitle.encoding.null? ? nil : String.new(t.u.subtitle.encoding)
            tracks << SubtitleTrack.new(
              id: t.id,
              name: name,
              language: lang,
              encoding: enc
            )
          end
        end
        tracks
      end

      # Adds an external slave track (e.g. an external .srt subtitle or audio dub)
      def add_slave(slave_type : LibVLC::MediaSlaveType, uri : String, priority : UInt32 = 1_u32) : Bool
        res = LibVLC.libvlc_media_slaves_add(@handle, slave_type, priority, uri)
        res == 0
      end

      # Helper to read a specific LibVLC metadata string
      def get_meta(meta : LibVLC::Meta) : String?
        ptr = LibVLC.libvlc_media_get_meta(@handle, meta)
        return nil if ptr.null?
        String.new(ptr)
      end

      # Iterates over native media tracks safely
      private def each_track(&block : LibVLC::MediaTrack -> Nil) : Nil
        raw_tracks = Pointer(Pointer(LibVLC::MediaTrack)).null
        count = LibVLC.libvlc_media_tracks_get(@handle, pointerof(raw_tracks))
        return if count == 0 || raw_tracks.null?

        begin
          count.times do |i|
            track_ptr = raw_tracks[i]
            block.call(track_ptr.value) unless track_ptr.null?
          end
        ensure
          LibVLC.libvlc_media_tracks_release(raw_tracks, count)
        end
      end

      private def fourcc_to_s(fourcc : UInt32) : String
        c1 = (fourcc & 0xFF).chr
        c2 = ((fourcc >> 8) & 0xFF).chr
        c3 = ((fourcc >> 16) & 0xFF).chr
        c4 = ((fourcc >> 24) & 0xFF).chr
        chars = [c1, c2, c3, c4]
        if chars.all? { |c| c.ascii_alphanumeric? || c == ' ' }
          chars.join.strip
        else
          sprintf("0x%08X", fourcc)
        end
      end

      def finalize
        unless @handle.null?
          LibVLC.libvlc_media_release(@handle)
          @handle = Pointer(Void).null.as(LibVLC::Media)
        end
      end
    end
  end
end
