module Emerald
  module VLC
    # Thread-safe double-buffered video frame surface for LibVLC memory decoding.
    class VideoFrameBuffer
      getter width : UInt32
      getter height : UInt32
      getter pitch : UInt32
      getter? has_new_frame : Bool = false

      def has_new_frame : Bool
        @has_new_frame
      end

      @mutex : Thread::Mutex
      @buffer_a : Slice(UInt8)
      @buffer_b : Slice(UInt8)
      @write_buffer : Slice(UInt8)
      @read_buffer : Slice(UInt8)

      def initialize(@width : UInt32 = 0_u32, @height : UInt32 = 0_u32)
        @pitch = @width * 4_u32
        @mutex = Thread::Mutex.new

        size = (@pitch * @height).to_i32
        if size > 0
          @buffer_a = Slice(UInt8).new(size, 0_u8)
          @buffer_b = Slice(UInt8).new(size, 0_u8)
        else
          @buffer_a = Slice(UInt8).empty
          @buffer_b = Slice(UInt8).empty
        end

        @write_buffer = @buffer_a
        @read_buffer = @buffer_b
      end

      # Resizes buffers when video resolution changes
      def resize(new_width : UInt32, new_height : UInt32) : Nil
        @mutex.synchronize do
          @width = new_width
          @height = new_height
          @pitch = new_width * 4_u32
          size = (@pitch * new_height).to_i32

          @buffer_a = Slice(UInt8).new(size, 0_u8)
          @buffer_b = Slice(UInt8).new(size, 0_u8)
          @write_buffer = @buffer_a
          @read_buffer = @buffer_b
          @has_new_frame = false
        end
      end

      # Returns the memory pointer where LibVLC decodes the upcoming frame
      def lock_write_buffer : Pointer(UInt8)
        @write_buffer.to_unsafe
      end

      # Commits the decoded frame and swaps write and read buffers
      def unlock_and_swap : Nil
        @mutex.synchronize do
          # Swap buffers
          tmp = @read_buffer
          @read_buffer = @write_buffer
          @write_buffer = tmp
          @has_new_frame = true
        end
      end

      # Pulls the latest decoded frame for uploading to Godot's ImageTexture.
      # Returns nil if no new frame has arrived since last pull.
      def pull_frame(&block : Slice(UInt8), UInt32, UInt32 -> Nil) : Bool
        return false unless @has_new_frame

        @mutex.synchronize do
          return false unless @has_new_frame
          @has_new_frame = false
          block.call(@read_buffer, @width, @height)
          true
        end
      end

      # Copies read buffer bytes into an existing destination slice
      def copy_read_buffer_to(dest : Slice(UInt8)) : Bool
        return false unless @has_new_frame

        @mutex.synchronize do
          return false unless @has_new_frame
          len = Math.min(@read_buffer.size, dest.size)
          dest[0, len].copy_from(@read_buffer[0, len])
          @has_new_frame = false
          true
        end
      end

      # Total size of a single frame buffer in bytes
      def byte_size : Int32
        (@pitch * @height).to_i32
      end
    end
  end
end
