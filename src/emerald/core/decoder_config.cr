require "./hardware_acceleration"

module Emerald
  module Core
    # Pure configuration struct for video decoding and hardware acceleration parameters.
    # Adheres to the Core Engine Layer standard: pure structs, zero-allocation, explicit state.
    struct VideoDecoderConfig
      property hardware_acceleration : HardwareAcceleration
      property thread_count : Int32
      property low_latency : Bool
      property drop_late_frames : Bool
      property fast_decoding : Bool
      property network_caching_ms : Int32
      property extra_options : Array(String)

      def initialize(
        @hardware_acceleration : HardwareAcceleration = HardwareAcceleration::Auto,
        @thread_count : Int32 = 0,
        @low_latency : Bool = true,
        @drop_late_frames : Bool = true,
        @fast_decoding : Bool = false,
        @network_caching_ms : Int32 = 1000,
        @extra_options : Array(String) = Array(String).new
      )
      end

      # Generates per-media options for LibVLC media loading
      def to_media_options : Array(String)
        opts = Array(String).new
        opts << @hardware_acceleration.to_media_option

        if @thread_count > 0
          opts << ":avcodec-threads=#{@thread_count}"
        end

        if @low_latency
          opts << ":network-caching=#{Math.min(@network_caching_ms, 300)}"
          opts << ":live-caching=300"
          opts << ":file-caching=300"
        else
          opts << ":network-caching=#{@network_caching_ms}"
        end

        if @drop_late_frames
          opts << ":drop-late-frames"
        else
          opts << ":no-drop-late-frames"
        end

        if @fast_decoding
          # Skip loop filter for non-reference frames to speed up decoding
          opts << ":avcodec-skiploopfilter=1"
          opts << ":avcodec-fast"
        end

        @extra_options.each do |extra|
          # Ensure media options start with colon
          formatted = extra.starts_with?(":") ? extra : ":#{extra.sub(/^--/, "")}"
          opts << formatted
        end

        opts
      end

      # Generates CLI arguments for LibVLC process instance initialization
      def to_instance_args : Array(String)
        args = Array(String).new
        args << @hardware_acceleration.to_vlc_arg
        args << "--avcodec-threads=#{@thread_count}" if @thread_count > 0
        args << "--network-caching=#{@network_caching_ms}"
        args << "--drop-late-frames" if @drop_late_frames
        args << "--avcodec-fast" if @fast_decoding
        args
      end

      # Fluent mutation helpers
      def with_hw_accel(accel : HardwareAcceleration) : VideoDecoderConfig
        copy = self
        copy.hardware_acceleration = accel
        copy
      end

      def with_threads(threads : Int32) : VideoDecoderConfig
        copy = self
        copy.thread_count = threads
        copy
      end

      def with_low_latency(enabled : Bool = true) : VideoDecoderConfig
        copy = self
        copy.low_latency = enabled
        copy
      end

      def with_drop_late_frames(enabled : Bool = true) : VideoDecoderConfig
        copy = self
        copy.drop_late_frames = enabled
        copy
      end

      def with_fast_decoding(enabled : Bool = true) : VideoDecoderConfig
        copy = self
        copy.fast_decoding = enabled
        copy
      end
    end
  end
end
