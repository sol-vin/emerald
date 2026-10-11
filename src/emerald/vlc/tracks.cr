module Emerald
  module VLC
    # Represents an audio stream or language dub track in a media source.
    class AudioTrack
      getter id : Int32
      getter name : String
      getter channels : UInt32
      getter sample_rate : UInt32
      getter codec : String
      getter language : String?

      def initialize(
        @id : Int32,
        @name : String,
        @channels : UInt32 = 2_u32,
        @sample_rate : UInt32 = 44100_u32,
        @codec : String = "",
        @language : String? = nil
      )
      end

      # Human-friendly channel description (Mono, Stereo, 5.1 Surround, etc.)
      def channel_layout : String
        case @channels
        when 1 then "Mono"
        when 2 then "Stereo"
        when 6 then "5.1 Surround"
        when 8 then "7.1 Surround"
        else        "#{@channels} Channels"
        end
      end

      def to_s(io : IO) : Void
        io << "AudioTrack(id: #{@id}, name: #{@name.inspect}, channels: #{channel_layout}, rate: #{@sample_rate}Hz"
        io << ", lang: #{@language}" if @language
        io << ")"
      end
    end

    # Represents a video stream track in a media source.
    class VideoTrack
      getter id : Int32
      getter name : String
      getter width : UInt32
      getter height : UInt32
      getter frame_rate : Float64
      getter codec : String
      getter aspect_ratio : String?

      def initialize(
        @id : Int32,
        @name : String,
        @width : UInt32 = 0_u32,
        @height : UInt32 = 0_u32,
        @frame_rate : Float64 = 0.0,
        @codec : String = "",
        @aspect_ratio : String? = nil
      )
      end

      # Returns resolution string formatted as "WIDTHxHEIGHT" (e.g. "1920x1080")
      def resolution : String
        "#{@width}x#{@height}"
      end

      def to_s(io : IO) : Void
        io << "VideoTrack(id: #{@id}, name: #{@name.inspect}, resolution: #{resolution}, fps: #{@frame_rate.round(2)}"
        io << ", codec: #{@codec}" unless @codec.empty?
        io << ")"
      end
    end

    # Represents a subtitle / closed-caption / SPU stream track.
    class SubtitleTrack
      getter id : Int32
      getter name : String
      getter language : String?
      getter encoding : String?

      def initialize(
        @id : Int32,
        @name : String,
        @language : String? = nil,
        @encoding : String? = nil
      )
      end

      def to_s(io : IO) : Void
        io << "SubtitleTrack(id: #{@id}, name: #{@name.inspect}"
        io << ", lang: #{@language}" if @language
        io << ")"
      end
    end
  end
end
