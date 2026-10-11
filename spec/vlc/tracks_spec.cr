require "../spec_helper"

describe "Emerald Track Models" do
  it "formats AudioTrack channel layout" do
    mono = Emerald::VLC::AudioTrack.new(id: 1, name: "Voice", channels: 1_u32)
    mono.channel_layout.should eq("Mono")

    stereo = Emerald::VLC::AudioTrack.new(id: 2, name: "Main", channels: 2_u32)
    stereo.channel_layout.should eq("Stereo")

    surround = Emerald::VLC::AudioTrack.new(id: 3, name: "Cinema", channels: 6_u32)
    surround.channel_layout.should eq("5.1 Surround")
  end

  it "formats VideoTrack resolution and aspect" do
    vt = Emerald::VLC::VideoTrack.new(
      id: 1,
      name: "Main Video",
      width: 3840_u32,
      height: 2160_u32,
      frame_rate: 60.0,
      codec: "H264"
    )
    vt.resolution.should eq("3840x2160")
    vt.codec.should eq("H264")
  end

  it "creates SubtitleTrack with language" do
    st = Emerald::VLC::SubtitleTrack.new(
      id: 1,
      name: "English Dialogue",
      language: "en"
    )
    st.id.should eq(1)
    st.language.should eq("en")
  end
end
