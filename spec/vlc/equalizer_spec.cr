require "../spec_helper"

describe Emerald::VLC::Equalizer do
  it "lists standard industry presets" do
    Emerald::VLC::Equalizer::PRESETS.size.should be >= 18
    Emerald::VLC::Equalizer::PRESETS.should contain("Rock")
    Emerald::VLC::Equalizer::PRESETS.should contain("Pop")
    Emerald::VLC::Equalizer::PRESETS.should contain("Classical")
    Emerald::VLC::Equalizer::PRESETS.should contain("FullBass")
  end

  it "creates an equalizer from a preset name" do
    eq = Emerald::VLC::Equalizer.from_preset("Rock")
    eq.should_not be_nil
    eq.band_count.should eq(10_u32)
  end

  it "raises ArgumentError for unknown preset" do
    expect_raises(ArgumentError) do
      Emerald::VLC::Equalizer.from_preset("NonExistentPresetXYZ")
    end
  end

  it "adjusts preamp within -20 to +20 dB range" do
    eq = Emerald::VLC::Equalizer.new
    eq.preamp = 5.5_f32
    eq.preamp.should be_close(5.5_f32, 0.1)

    # Clamping tests
    eq.preamp = 40.0_f32
    eq.preamp.should be_close(20.0_f32, 0.1)

    eq.preamp = -35.0_f32
    eq.preamp.should be_close(-20.0_f32, 0.1)
  end

  it "reads and sets individual frequency band amplification" do
    eq = Emerald::VLC::Equalizer.new
    eq.band_count.should eq(10_u32)
    eq.band_frequency(0_u32).should be_close(31.25_f32, 0.1)

    eq.set_amp(0_u32, 8.0_f32)
    eq.amp(0_u32).should be_close(8.0_f32, 0.2)
  end
end
