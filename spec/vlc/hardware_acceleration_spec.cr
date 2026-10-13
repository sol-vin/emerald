require "../spec_helper"

describe Emerald::Core::HardwareAcceleration do
  it "maps enum variants to LibVLC avcodec-hw values and options" do
    Emerald::Core::HardwareAcceleration::None.vlc_value.should eq("none")
    Emerald::Core::HardwareAcceleration::Auto.vlc_value.should eq("any")
    Emerald::Core::HardwareAcceleration::D3D11VA.vlc_value.should eq("d3d11va")
    Emerald::Core::HardwareAcceleration::DXVA2.vlc_value.should eq("dxva2")
    Emerald::Core::HardwareAcceleration::VAAPI.vlc_value.should eq("vaapi")
    Emerald::Core::HardwareAcceleration::VDPAU.vlc_value.should eq("vdpau")
    Emerald::Core::HardwareAcceleration::VideoToolbox.vlc_value.should eq("videotoolbox")
    Emerald::Core::HardwareAcceleration::MediaCodec.vlc_value.should eq("mediacodec")
    Emerald::Core::HardwareAcceleration::NVDEC.vlc_value.should eq("nvdec")

    Emerald::Core::HardwareAcceleration::D3D11VA.to_vlc_arg.should eq("--avcodec-hw=d3d11va")
    Emerald::Core::HardwareAcceleration::D3D11VA.to_media_option.should eq(":avcodec-hw=d3d11va")
    Emerald::Core::HardwareAcceleration::None.enabled?.should be_false
    Emerald::Core::HardwareAcceleration::Auto.enabled?.should be_true
    Emerald::Core::HardwareAcceleration::NVDEC.description.should contain("NVIDIA")
  end

  it "parses strings and symbols case-insensitively" do
    Emerald::Core::HardwareAcceleration.parse(:d3d11va).should eq(Emerald::Core::HardwareAcceleration::D3D11VA)
    Emerald::Core::HardwareAcceleration.parse("D3D11").should eq(Emerald::Core::HardwareAcceleration::D3D11VA)
    Emerald::Core::HardwareAcceleration.parse("dxva2").should eq(Emerald::Core::HardwareAcceleration::DXVA2)
    Emerald::Core::HardwareAcceleration.parse(:vaapi).should eq(Emerald::Core::HardwareAcceleration::VAAPI)
    Emerald::Core::HardwareAcceleration.parse("vdpau").should eq(Emerald::Core::HardwareAcceleration::VDPAU)
    Emerald::Core::HardwareAcceleration.parse("videotoolbox").should eq(Emerald::Core::HardwareAcceleration::VideoToolbox)
    Emerald::Core::HardwareAcceleration.parse("mediacodec").should eq(Emerald::Core::HardwareAcceleration::MediaCodec)
    Emerald::Core::HardwareAcceleration.parse(:nvdec).should eq(Emerald::Core::HardwareAcceleration::NVDEC)
    Emerald::Core::HardwareAcceleration.parse("software").should eq(Emerald::Core::HardwareAcceleration::None)
    Emerald::Core::HardwareAcceleration.parse("auto").should eq(Emerald::Core::HardwareAcceleration::Auto)
    Emerald::Core::HardwareAcceleration.parse?("invalid_backend").should be_nil
  end

  it "detects platform support and default backend" do
    default_hw = Emerald::Core::HardwareAcceleration.default_for_platform
    default_hw.enabled?.should be_true
    default_hw.supported_on_current_platform?.should be_true
  end
end

describe Emerald::Core::VideoDecoderConfig do
  it "generates per-media and instance options from pure config struct" do
    cfg = Emerald::Core::VideoDecoderConfig.new(
      hardware_acceleration: Emerald::Core::HardwareAcceleration::D3D11VA,
      thread_count: 4,
      low_latency: true,
      drop_late_frames: true,
      fast_decoding: true,
      network_caching_ms: 500,
      extra_options: ["--avcodec-dr"]
    )

    media_opts = cfg.to_media_options
    media_opts.should contain(":avcodec-hw=d3d11va")
    media_opts.should contain(":avcodec-threads=4")
    media_opts.should contain(":network-caching=300")
    media_opts.should contain(":drop-late-frames")
    media_opts.should contain(":avcodec-fast")
    media_opts.should contain(":avcodec-dr")

    inst_args = cfg.to_instance_args
    inst_args.should contain("--avcodec-hw=d3d11va")
    inst_args.should contain("--avcodec-threads=4")
    inst_args.should contain("--drop-late-frames")
    inst_args.should contain("--avcodec-fast")
  end

  it "supports non-mutating fluent copy helpers" do
    base = Emerald::Core::VideoDecoderConfig.new
    modified = base.with_hw_accel(Emerald::Core::HardwareAcceleration::NVDEC)
      .with_threads(8)
      .with_low_latency(false)
      .with_drop_late_frames(false)
      .with_fast_decoding(true)

    base.hardware_acceleration.should eq(Emerald::Core::HardwareAcceleration::Auto)
    modified.hardware_acceleration.should eq(Emerald::Core::HardwareAcceleration::NVDEC)
    modified.thread_count.should eq(8)
    modified.low_latency.should be_false
    modified.drop_late_frames.should be_false
    modified.fast_decoding.should be_true
  end
end

describe Emerald::DSL::MediaBuilder do
  it "builds VideoDecoderConfig and Media using the declarative DSL" do
    cfg = Emerald.decoder_config("sample.mp4") do |m|
      m.d3d11va
      m.threads(6)
      m.low_latency(true)
      m.drop_late_frames(true)
      m.fast_decoding(true)
      m.network_caching(250)
      m.option(":no-audio")
    end

    cfg.hardware_acceleration.should eq(Emerald::Core::HardwareAcceleration::D3D11VA)
    cfg.thread_count.should eq(6)
    cfg.low_latency.should be_true
    cfg.fast_decoding.should be_true
    cfg.network_caching_ms.should eq(250)
    cfg.to_media_options.should contain(":avcodec-hw=d3d11va")
    cfg.to_media_options.should contain(":no-audio")

    media = Emerald.media("https://example.com/stream.mp4") do |m|
      m.nvdec
      m.threads(4)
      m.low_latency(true)
    end

    media.options.should contain(":avcodec-hw=nvdec")
    media.options.should contain(":avcodec-threads=4")
  end
end
