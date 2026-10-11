require "../spec_helper"

describe Emerald::VLC::Metadata do
  it "formats duration correctly" do
    meta = Emerald::VLC::Metadata.new(duration_ms: 125_000_i64)
    meta.formatted_duration.should eq("02:05")
    meta.duration_seconds.should eq(125.0)

    long_meta = Emerald::VLC::Metadata.new(duration_ms: 3_725_000_i64)
    long_meta.formatted_duration.should eq("01:02:05")
  end

  it "serializes metadata to hash" do
    meta = Emerald::VLC::Metadata.new(
      title: "Epic Track",
      artist: "Crystal Composer",
      album: "Lapis Soundtrack",
      duration_ms: 180_000_i64
    )

    h = meta.to_h
    h["title"].should eq("Epic Track")
    h["artist"].should eq("Crystal Composer")
    h["album"].should eq("Lapis Soundtrack")
    h["duration"].should eq("03:00")
  end
end
