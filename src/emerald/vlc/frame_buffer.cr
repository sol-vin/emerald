module Emerald
  module VLC
    # Thread-safe double-buffered video frame surface for LibVLC memory decoding.
    # Uses native LibC allocation and OS Thread::Mutex to guarantee zero Boehm GC interference
    # when accessed from LibVLC's background native worker threads.
    class VideoFrameBuffer
      getter width : UInt32 = 0_u32
      getter height : UInt32 = 0_u32
      getter pitch : UInt32 = 0_u32
      getter? has_new_frame : Bool = false

      def has_new_frame : Bool
        @has_new_frame
      end

      @mutex : ::Thread::Mutex
      @raw_a : Pointer(UInt8) = Pointer(UInt8).null
      @raw_b : Pointer(UInt8) = Pointer(UInt8).null
      @write_ptr : Pointer(UInt8) = Pointer(UInt8).null
      @read_ptr : Pointer(UInt8) = Pointer(UInt8).null
      @size : Int32 = 0

      def initialize(@width : UInt32 = 0_u32, @height : UInt32 = 0_u32)
        @mutex = ::Thread::Mutex.new
        @pitch = @width * 4_u32
        alloc_buffers((@pitch * @height).to_i32)
      end

      private def alloc_buffers(sz : Int32) : Nil
        if !@raw_a.null?
          LibC.free(@raw_a.as(Void*))
          @raw_a = Pointer(UInt8).null
        end
        if !@raw_b.null?
          LibC.free(@raw_b.as(Void*))
          @raw_b = Pointer(UInt8).null
        end

        @size = sz
        if sz > 0
          @raw_a = LibC.malloc(sz.to_u64).as(UInt8*)
          @raw_b = LibC.malloc(sz.to_u64).as(UInt8*)
          if !@raw_a.null?
            @raw_a.clear(sz)
          end
          if !@raw_b.null?
            @raw_b.clear(sz)
          end
        end

        @write_ptr = @raw_a
        @read_ptr = @raw_b
      end

      # Resizes buffers when video resolution changes
      def resize(new_width : UInt32, new_height : UInt32) : Nil
        @mutex.synchronize do
          @width = new_width
          @height = new_height
          @pitch = new_width * 4_u32
          alloc_buffers((@pitch * new_height).to_i32)
          @has_new_frame = false
        end
      end

      # Returns the memory pointer where LibVLC decodes the upcoming frame
      def lock_write_buffer : Pointer(UInt8)
        @write_ptr
      end

      # Commits the decoded frame and swaps write and read buffers
      def unlock_and_swap : Nil
        @mutex.synchronize do
          tmp = @read_ptr
          @read_ptr = @write_ptr
          @write_ptr = tmp
          @has_new_frame = true
        end
      end

      # Pulls the latest decoded frame for uploading to Godot's ImageTexture.
      # Must be called from Godot's main thread during _process.
      def pull_frame(&block : Slice(UInt8), UInt32, UInt32 -> Nil) : Bool
        return false unless @has_new_frame
        return false if @read_ptr.null? || @size <= 0

        @mutex.synchronize do
          return false unless @has_new_frame
          return false if @read_ptr.null? || @size <= 0
          @has_new_frame = false
          slice = Slice.new(@read_ptr, @size)
          block.call(slice, @width, @height)
          true
        end
      end

      # Copies read buffer bytes into an existing destination slice
      def copy_read_buffer_to(dest : Slice(UInt8)) : Bool
        return false unless @has_new_frame
        return false if @read_ptr.null? || @size <= 0

        @mutex.synchronize do
          return false unless @has_new_frame
          return false if @read_ptr.null? || @size <= 0
          len = Math.min(@size, dest.size)
          dest[0, len].copy_from(Slice.new(@read_ptr, len))
          @has_new_frame = false
          true
        end
      end

      # Total size of a single frame buffer in bytes
      def byte_size : Int32
        @size
      end

      def finalize
        if !@raw_a.null?
          LibC.free(@raw_a.as(Void*))
          @raw_a = Pointer(UInt8).null
        end
        if !@raw_b.null?
          LibC.free(@raw_b.as(Void*))
          @raw_b = Pointer(UInt8).null
        end
      end
    end
  end
end
