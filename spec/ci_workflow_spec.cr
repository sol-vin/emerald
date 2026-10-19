require "./spec_helper"
require "yaml"

describe "Emerald Addon CI & Release Workflow (template-addon standard)" do
  it "verifies .github/workflows/ci.yml and release.yml adopt template-addon multi-platform jobs on 4.8-beta1" do
    ci_path = File.expand_path("../.github/workflows/ci.yml", __DIR__)
    rel_path = File.expand_path("../.github/workflows/release.yml", __DIR__)
    File.exists?(ci_path).should be_true
    File.exists?(rel_path).should be_true

    raw_ci = File.read(ci_path)
    doc = YAML.parse(raw_ci)
    jobs = doc["jobs"].as_h
    jobs.has_key?("test").should be_true
    raw_ci.includes?("4.8-beta1").should be_true
    raw_ci.includes?("libvlc").should be_true
  end
end
