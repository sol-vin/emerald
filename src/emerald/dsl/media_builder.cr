require "../core/hardware_acceleration"
require "../core/decoder_config"

module Emerald
  module DSL
    # Declarative builder for configuring media sources, hardware video acceleration,
    # and low-latency decoding parameters using yield contexts.
    # Adheres to the Declarative DSL Codex: ergonomic block receivers, fluent chaining.
    class MediaBuilder
      getter source : String
      property hardware_acceleration : Core::HardwareAcceleration
      property thread_count : Int32
      property low_latency : Bool
      property drop_late_frames : Bool
      property fast_decoding : Bool
      property network_caching_ms : Int32
      getter custom_options : Array(String)

      def initialize(@source : String)
        @hardware_acceleration = Core::HardwareAcceleration::Auto
        @thread_count = 0
        @low_latency = true
        @drop_late_frames = true
        @fast_decoding = false
        @network_caching_ms = 1000
        @custom_options = Array(String).new
      end

      # Ergonomic hardware acceleration setter with symbols, string, or enum
      def hw_accel(mode : Core::HardwareAcceleration | Symbol | String) : self
        @hardware_acceleration = case mode
                                 when Core::HardwareAcceleration then mode
                                 else Core::HardwareAcceleration.parse(mode)
                                 end
        self
      end

      # Shorthand helpers for specific hardware acceleration backends
      def d3d11va : self
        hw_accel(Core::HardwareAcceleration::D3D11VA)
      end

      def dxva2 : self
        hw_accel(Core::HardwareAcceleration::DXVA2)
      end

      def vaapi : self
        hw_accel(Core::HardwareAcceleration::VAAPI)
      end

      def vdpau : self
        hw_accel(Core::HardwareAcceleration::VDPAU)
      end

      def videotoolbox : self
        hw_accel(Core::HardwareAcceleration::VideoToolbox)
      end

      def mediacodec : self
        hw_accel(Core::HardwareAcceleration::MediaCodec)
      end

      def nvdec : self
        hw_accel(Core::HardwareAcceleration::NVDEC)
      end

      def software_only : self
        hw_accel(Core::HardwareAcceleration::None)
      end

      def auto_accel : self
        hw_accel(Core::HardwareAcceleration::Auto)
      end

      def threads(count : Int32) : self
        @thread_count = count
        self
      end

      def low_latency(enabled : Bool = true) : self
        @low_latency = enabled
        self
      end

      def drop_late_frames(enabled : Bool = true) : self
        @drop_late_frames = enabled
        self
      end

      def fast_decoding(enabled : Bool = true) : self
        @fast_decoding = enabled
        self
      end

      def network_caching(duration : Time::Span) : self
        @network_caching_ms = duration.total_milliseconds.to_i32
        self
      end

      def network_caching(ms : Int32) : self
        @network_caching_ms = ms
        self
      end

      def option(opt : String) : self
        @custom_options << opt
        self
      end

      # Compiles builder into pure Core::VideoDecoderConfig
      def to_config : Core::VideoDecoderConfig
        Core::VideoDecoderConfig.new(
          hardware_acceleration: @hardware_acceleration,
          thread_count: @thread_count,
          low_latency: @low_latency,
          drop_late_frames: @drop_late_frames,
          fast_decoding: @fast_decoding,
          network_caching_ms: @network_caching_ms,
          extra_options: @custom_options
        )
      end

      # Builds a configured VLC::Media instance with hardware acceleration options applied
      def to_media(instance : VLC::Instance? = nil) : VLC::Media
        resolved = Emerald.resolve_source_path(@source)
        VLC::Media.new(resolved, instance, to_config)
      end
    end
  end

  # Declarative DSL entry point for configuring media with hardware video acceleration
  def self.media(source : String, &block : DSL::MediaBuilder ->) : VLC::Media
    builder = DSL::MediaBuilder.new(source)
    yield builder
    builder.to_media
  end

  # Declarative DSL entry point for building a VideoDecoderConfig
  def self.decoder_config(source : String = "", &block : DSL::MediaBuilder ->) : Core::VideoDecoderConfig
    builder = DSL::MediaBuilder.new(source)
    yield builder
    builder.to_config
  end
end
