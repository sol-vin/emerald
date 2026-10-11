module Emerald
  module VLC
    # 10-band audio graphic equalizer and preset manager.
    class Equalizer
      # 18 standard LibVLC equalizer presets
      PRESETS = [
        "Flat",
        "Classical",
        "Club",
        "Dance",
        "FullBass",
        "FullBassTreble",
        "FullTreble",
        "Headphones",
        "LargeHall",
        "Live",
        "Party",
        "Pop",
        "Reggae",
        "Rock",
        "Ska",
        "Soft",
        "SoftRock",
        "Techno",
        "Vocal"
      ]

      # 10 standard ISO audio equalizer frequencies (in Hz)
      BAND_FREQUENCIES = [
        31.25_f32,
        62.5_f32,
        125.0_f32,
        250.0_f32,
        500.0_f32,
        1000.0_f32,
        2000.0_f32,
        4000.0_f32,
        8000.0_f32,
        16000.0_f32
      ]

      getter handle : LibVLC::Equalizer

      def initialize(handle : LibVLC::Equalizer? = nil)
        @handle = handle || LibVLC.libvlc_audio_equalizer_new
        if @handle.null?
          raise "Failed to create LibVLC Equalizer"
        end
      end

      # Creates an equalizer initialized with a standard preset name
      def self.from_preset(preset_name : String) : Equalizer
        idx = PRESETS.index { |p| p.compare(preset_name, case_insensitive: true) == 0 }
        unless idx
          raise ArgumentError.new("Unknown equalizer preset '#{preset_name}'. Available: #{PRESETS.join(", ")}")
        end
        from_preset_index(idx.to_u32)
      end

      # Creates an equalizer initialized with a preset index (0..18)
      def self.from_preset_index(index : UInt32) : Equalizer
        handle = LibVLC.libvlc_audio_equalizer_new_from_preset(index)
        if handle.null?
          raise "Failed to initialize Equalizer with preset index #{index}"
        end
        new(handle)
      end

      # Number of frequency bands supported (typically 10)
      def band_count : UInt32
        LibVLC.libvlc_audio_equalizer_get_band_count
      end

      # Gets center frequency for band index in Hz
      def band_frequency(band_index : UInt32) : Float32
        LibVLC.libvlc_audio_equalizer_get_band_frequency(band_index)
      end

      # Gets amplification in dB for band index (-20.0 dB .. +20.0 dB)
      def amp(band_index : UInt32) : Float32
        LibVLC.libvlc_audio_equalizer_get_amp_at_index(@handle, band_index)
      end

      # Sets amplification in dB for band index (-20.0 dB .. +20.0 dB)
      def set_amp(band_index : UInt32, amp_db : Float32) : Nil
        clamped = amp_db.clamp(-20.0_f32, 20.0_f32)
        LibVLC.libvlc_audio_equalizer_set_amp_at_index(@handle, clamped, band_index)
      end

      # Gets master pre-amplification gain in dB
      def preamp : Float32
        LibVLC.libvlc_audio_equalizer_get_preamp(@handle)
      end

      # Sets master pre-amplification gain in dB (-20.0 dB .. +20.0 dB)
      def preamp=(preamp_db : Float32) : Float32
        clamped = preamp_db.clamp(-20.0_f32, 20.0_f32)
        LibVLC.libvlc_audio_equalizer_set_preamp(@handle, clamped)
        clamped
      end

      def finalize
        unless @handle.null?
          LibVLC.libvlc_audio_equalizer_release(@handle)
          @handle = Pointer(Void).null.as(LibVLC::Equalizer)
        end
      end
    end
  end
end
