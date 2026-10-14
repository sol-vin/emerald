require "./spec_helper"
require "yaml"

describe "Emerald Addon CI Reusable Workflow Adoption (WO-041)" do
  it "verifies .github/workflows/ci.yml adopts sol-vin/lapis/.github/workflows/build-addon.yml@4.8-dev7" do
    wf_path = File.expand_path("../.github/workflows/ci.yml", __DIR__)
    File.exists?(wf_path).should be_true

    doc = YAML.parse(File.read(wf_path))
    job = doc["jobs"]["build-addon"]
    job["uses"].as_s.should eq("sol-vin/lapis/.github/workflows/build-addon.yml@4.8-dev7")
    job["with"]["addon-name"].as_s.should eq("emerald")
    job["with"]["lapis-ref"].as_s.should eq("4.8-dev7")
    job["with"]["install-libvlc"].as_s.should eq("true")
  end
end
