module Emerald
  module VLC
    # Thread-safe event queue bridging LibVLC background threads to Godot's main thread.
    # Uses a fixed ring-buffer and OS Thread::Mutex to guarantee zero Boehm GC allocations
    # or fiber context switches when handling LibVLC C callback notifications.
    class EventManager
      # Internal queued event payload (pure POD value type)
      struct QueuedEvent
        getter type : LibVLC::EventType
        getter time_ms : Int64
        getter position : Float32

        def initialize(
          @type : LibVLC::EventType = LibVLC::EventType::MediaPlayerNothingSpecial,
          @time_ms : Int64 = 0_i64,
          @position : Float32 = 0.0_f32
        )
        end
      end

      QUEUE_CAPACITY = 64

      getter handle : LibVLC::EventManager
      @queue : StaticArray(QueuedEvent, 64)
      @head : Int32 = 0
      @tail : Int32 = 0
      @count : Int32 = 0
      @mutex : ::Thread::Mutex
      @c_callback : LibVLC::EventCallback

      # Main-thread Crystal callbacks registered by player or node
      property on_playing : (-> Nil)?
      property on_paused : (-> Nil)?
      property on_stopped : (-> Nil)?
      property on_ended : (-> Nil)?
      property on_time_changed : (Int64 -> Nil)?
      property on_position_changed : (Float32 -> Nil)?
      property on_length_changed : (Int64 -> Nil)?
      property on_error : (String -> Nil)?

      def initialize(@handle : LibVLC::EventManager)
        @queue = StaticArray(QueuedEvent, 64).new(QueuedEvent.new)
        @mutex = ::Thread::Mutex.new

        # Native C callback trampoline - executes on LibVLC worker threads
        @c_callback = ->(event_ptr : LibVLC::Event*, user_data : Void*) {
          manager = Box(EventManager).unbox(user_data)
          manager.handle_native_event(event_ptr.value)
        }

        attach_all
      end

      # Called by LibVLC on a background worker thread.
      # Must perform ZERO allocations and only lock the OS Thread::Mutex.
      def handle_native_event(event : LibVLC::Event) : Nil
        ev_type = event.type
        @mutex.synchronize do
          if @count < QUEUE_CAPACITY
            @queue[@tail] = QueuedEvent.new(type: ev_type)
            @tail = (@tail + 1) % QUEUE_CAPACITY
            @count += 1
          end
        end
      end

      # Manually queues an error from Crystal wrapper
      def queue_error(message : String) : Nil
        @mutex.synchronize do
          if @count < QUEUE_CAPACITY
            @queue[@tail] = QueuedEvent.new(type: LibVLC::EventType::MediaPlayerEncounteredError)
            @tail = (@tail + 1) % QUEUE_CAPACITY
            @count += 1
          end
        end
      end

      # Dispatches all pending events to registered callbacks.
      # Must be called regularly on the main thread (e.g. from Godot _process).
      def poll_events : Nil
        # Drain events from ring buffer into temporary local array on the main thread
        events = StaticArray(QueuedEvent, 64).new(QueuedEvent.new)
        n_events = 0

        @mutex.synchronize do
          while @count > 0 && n_events < QUEUE_CAPACITY
            events[n_events] = @queue[@head]
            @head = (@head + 1) % QUEUE_CAPACITY
            @count -= 1
            n_events += 1
          end
        end

        # Dispatch on the main thread
        i = 0
        while i < n_events
          ev = events[i]
          case ev.type
          when LibVLC::EventType::MediaPlayerPlaying
            @on_playing.try(&.call)
          when LibVLC::EventType::MediaPlayerPaused
            @on_paused.try(&.call)
          when LibVLC::EventType::MediaPlayerStopped
            @on_stopped.try(&.call)
          when LibVLC::EventType::MediaPlayerEndReached
            @on_ended.try(&.call)
          when LibVLC::EventType::MediaPlayerTimeChanged
            @on_time_changed.try(&.call(ev.time_ms))
          when LibVLC::EventType::MediaPlayerPositionChanged
            @on_position_changed.try(&.call(ev.position))
          when LibVLC::EventType::MediaPlayerEncounteredError
            @on_error.try(&.call("LibVLC playback error encountered"))
          end
          i += 1
        end
      end

      private def attach_all : Nil
        boxed = Box.box(self)
        events = [
          LibVLC::EventType::MediaPlayerPlaying,
          LibVLC::EventType::MediaPlayerPaused,
          LibVLC::EventType::MediaPlayerStopped,
          LibVLC::EventType::MediaPlayerEndReached,
          LibVLC::EventType::MediaPlayerTimeChanged,
          LibVLC::EventType::MediaPlayerPositionChanged,
          LibVLC::EventType::MediaPlayerEncounteredError
        ]

        events.each do |ev|
          LibVLC.libvlc_event_attach(@handle, ev, @c_callback, boxed)
        end
      end

      def finalize
        unless @handle.null?
          events = [
            LibVLC::EventType::MediaPlayerPlaying,
            LibVLC::EventType::MediaPlayerPaused,
            LibVLC::EventType::MediaPlayerStopped,
            LibVLC::EventType::MediaPlayerEndReached,
            LibVLC::EventType::MediaPlayerTimeChanged,
            LibVLC::EventType::MediaPlayerPositionChanged,
            LibVLC::EventType::MediaPlayerEncounteredError
          ]

          boxed = Box.box(self)
          events.each do |ev|
            LibVLC.libvlc_event_detach(@handle, ev, @c_callback, boxed)
          end
        end
      end
    end
  end
end
