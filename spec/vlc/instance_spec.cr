require "../spec_helper"

describe Emerald::VLC::Instance do
  it "returns valid LibVLC version string" do
    version = Emerald::VLC::Instance.version
    version.should_not be_empty
    version.should contain("3.")
  end

  it "returns valid LibVLC compiler information" do
    compiler = Emerald::VLC::Instance.compiler
    compiler.should_not be_empty
  end

  it "initializes process-wide default singleton instance" do
    inst = Emerald::VLC::Instance.default
    inst.should_not be_nil
    inst.handle.null?.should be_false
  end
end
