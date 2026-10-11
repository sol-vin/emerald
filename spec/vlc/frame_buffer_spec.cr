require "../spec_helper"

describe Emerald::VLC::VideoFrameBuffer do
  it "initializes with correct pitch and memory size" do
    fb = Emerald::VLC::VideoFrameBuffer.new(1920_u32, 1080_u32)
    fb.width.should eq(1920_u32)
    fb.height.should eq(1080_u32)
    fb.pitch.should eq(1920_u32 * 4_u32)
    fb.byte_size.should eq(1920 * 1080 * 4)
    fb.has_new_frame?.should be_false
  end

  it "swaps write and read buffers upon unlock" do
    fb = Emerald::VLC::VideoFrameBuffer.new(320_u32, 240_u32)
    write_ptr = fb.lock_write_buffer
    write_ptr.null?.should be_false

    # Write test byte
    write_ptr[0] = 0xAA_u8

    # Unlock and swap
    fb.unlock_and_swap
    fb.has_new_frame?.should be_true

    pulled = false
    fb.pull_frame do |pixels, w, h|
      w.should eq(320_u32)
      h.should eq(240_u32)
      pixels[0].should eq(0xAA_u8)
      pulled = true
    end

    pulled.should be_true
    fb.has_new_frame?.should be_false
  end

  it "resizes buffers dynamically" do
    fb = Emerald::VLC::VideoFrameBuffer.new(100_u32, 100_u32)
    fb.byte_size.should eq(40000)

    fb.resize(1280_u32, 720_u32)
    fb.width.should eq(1280_u32)
    fb.height.should eq(720_u32)
    fb.byte_size.should eq(1280 * 720 * 4)
  end
end
