require "../spec_helper"

describe "Emerald Godot Nodes" do
  it "defines EmeraldVideoPlayer with default properties" do
    EmeraldVideoPlayer.should_not be_nil
    Emerald::VideoPlayer.should eq(EmeraldVideoPlayer)
  end

  it "defines EmeraldAudioPlayer with default properties" do
    EmeraldAudioPlayer.should_not be_nil
    Emerald::AudioPlayer.should eq(EmeraldAudioPlayer)
  end

  it "defines EmeraldVideoPlayer3D with default properties" do
    EmeraldVideoPlayer3D.should_not be_nil
    Emerald::VideoPlayer3D.should eq(EmeraldVideoPlayer3D)
  end

  it "defines EmeraldMediaResource with metadata properties" do
    EmeraldMediaResource.should_not be_nil
    Emerald::MediaResource.should eq(EmeraldMediaResource)
  end

  it "defines ResourceFormatLoaderEmerald with recognized extensions" do
    ResourceFormatLoaderEmerald.should_not be_nil
    Emerald::ResourceFormatLoader.should eq(ResourceFormatLoaderEmerald)
    ResourceFormatLoaderEmerald::EXTENSIONS.should contain("mp4")
    ResourceFormatLoaderEmerald::EXTENSIONS.should contain("mkv")
    ResourceFormatLoaderEmerald::EXTENSIONS.should contain("webm")
  end
end
