module Emerald
  module Core
    # Represents the hardware video acceleration backend for LibVLC / FFmpeg avcodec.
    # Adheres to the Core Engine Layer standard: pure enum, zero allocation, explicit mapping.
    enum HardwareAcceleration
      None          # Software decoding only (:avcodec-hw=none)
      Auto          # Automatic hardware acceleration (:avcodec-hw=any)
      D3D11VA       # Direct3D 11 Video Acceleration on Windows (:avcodec-hw=d3d11va)
      DXVA2         # DirectX Video Acceleration 2.0 on Windows (:avcodec-hw=dxva2)
      VAAPI         # Video Acceleration API on Linux (:avcodec-hw=vaapi)
      VDPAU         # Video Decode and Presentation API on Unix/Linux (:avcodec-hw=vdpau)
      VideoToolbox  # Apple VideoToolbox hardware acceleration (:avcodec-hw=videotoolbox)
      MediaCodec    # Android MediaCodec hardware acceleration (:avcodec-hw=mediacodec)
      NVDEC         # NVIDIA NVDEC hardware acceleration (:avcodec-hw=nvdec)

      # Returns the LibVLC avcodec option value
      def vlc_value : String
        case self
        in None         then "none"
        in Auto         then "any"
        in D3D11VA      then "d3d11va"
        in DXVA2        then "dxva2"
        in VAAPI        then "vaapi"
        in VDPAU        then "vdpau"
        in VideoToolbox then "videotoolbox"
        in MediaCodec   then "mediacodec"
        in NVDEC        then "nvdec"
        end
      end

      # Returns the command-line argument for LibVLC instance initialization
      def to_vlc_arg : String
        "--avcodec-hw=#{vlc_value}"
      end

      # Returns the per-media option string for libvlc_media_add_option
      def to_media_option : String
        ":avcodec-hw=#{vlc_value}"
      end

      # Returns true if hardware acceleration is enabled (not None)
      def enabled? : Bool
        !none?
      end

      # Human-readable display description
      def description : String
        case self
        in None         then "Software Decoding (CPU)"
        in Auto         then "Automatic Hardware Acceleration"
        in D3D11VA      then "Direct3D 11 Video Acceleration (Windows)"
        in DXVA2        then "DirectX Video Acceleration 2.0 (Windows)"
        in VAAPI        then "Video Acceleration API (Linux)"
        in VDPAU        then "Video Decode and Presentation API (Unix)"
        in VideoToolbox then "Apple VideoToolbox (macOS/iOS)"
        in MediaCodec   then "Android MediaCodec"
        in NVDEC        then "NVIDIA NVDEC Hardware Decoder"
        end
      end

      # Returns true if the backend is native to the current OS platform
      def supported_on_current_platform? : Bool
        case self
        in None, Auto
          true
        in D3D11VA, DXVA2
          {% if flag?(:windows) %}
            true
          {% else %}
            false
          {% end %}
        in VAAPI, VDPAU
          {% if flag?(:linux) %}
            true
          {% else %}
            false
          {% end %}
        in VideoToolbox
          {% if flag?(:darwin) %}
            true
          {% else %}
            false
          {% end %}
        in MediaCodec
          {% if flag?(:android) %}
            true
          {% else %}
            false
          {% end %}
        in NVDEC
          true
        end
      end

      # Determines the optimal default hardware acceleration backend for the host platform
      def self.default_for_platform : HardwareAcceleration
        {% if flag?(:windows) %}
          D3D11VA
        {% elsif flag?(:darwin) %}
          VideoToolbox
        {% elsif flag?(:linux) %}
          VAAPI
        {% elsif flag?(:android) %}
          MediaCodec
        {% else %}
          Auto
        {% end %}
      end

      # Parses a string or symbol into a HardwareAcceleration enum, case-insensitively
      def self.parse?(value : String | Symbol) : HardwareAcceleration?
        val = value.to_s.strip.downcase.gsub(/[-_]/, "")
        case val
        when "none", "disabled", "off", "software", "cpu"
          None
        when "auto", "any", "enabled", "on", "hw"
          Auto
        when "d3d11va", "d3d11", "direct3d11"
          D3D11VA
        when "dxva2", "dxva", "directx"
          DXVA2
        when "vaapi", "va"
          VAAPI
        when "vdpau"
          VDPAU
        when "videotoolbox", "vt", "apple"
          VideoToolbox
        when "mediacodec", "android"
          MediaCodec
        when "nvdec", "cuda", "nvidia"
          NVDEC
        else
          nil
        end
      end

      def self.parse(value : String | Symbol) : HardwareAcceleration
        parse?(value) || raise ArgumentError.new("Unknown hardware acceleration backend: '#{value}'")
      end
    end
  end
end
