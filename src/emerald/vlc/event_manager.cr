module Emerald
  module VLC
    # Thread-safe event queue bridging LibVLC background threads to Godot's main thread.
    class EventManager
      # Internal queued event payload
      struct QueuedEvent
        getter type : LibVLC::EventType
        getter time_ms : Int64
        getter position : Float32
        getter error_message : String?

        def initialize(
          @type : LibVLC::EventType,
          @time_ms : Int64 = 0_i64,
          @position : Float32 = 0.0_f32,
          @error_message : String? = nil
        )
        end
      end

      getter handle : LibVLC::EventManager
      @queue : Array(QueuedEvent)
      @mutex : ::Mutex
      @c_callback : LibVLC::EventCallback

      # Crystal callbacks registered by player or node
      property on_playing : (-> Nil)?
      property on_paused : (-> Nil)?
      property on_stopped : (-> Nil)?
      property on_ended : (-> Nil)?
      property on_time_changed : (Int64 -> Nil)?
      property on_position_changed : (Float32 -> Nil)?
      property on_length_changed : (Int64 -> Nil)?
      property on_error : (String -> Nil)?

      def initialize(@handle : LibVLC::EventManager)
        @queue = Array(QueuedEvent).new
        @mutex = ::Mutex.new

        # Native C callback trampoline
        @c_callback = ->(event_ptr : LibVLC::Event*, user_data : Void*) {
          manager = Box(EventManager).unbox(user_data)
          manager.handle_native_event(event_ptr.value)
        }

        attach_all
      end

      # Called by LibVLC on a background worker thread
      def handle_native_event(event : LibVLC::Event) : Nil
        queued = QueuedEvent.new(type: event.type)

        @mutex.synchronize do
          @queue << queued
        end
      end

      # Manually queues an error from Crystal wrapper
      def queue_error(message : String) : Nil
        @mutex.synchronize do
          @queue << QueuedEvent.new(
            type: LibVLC::EventType::MediaPlayerEncounteredError,
            error_message: message
          )
        end
      end

      # Dispatches all pending events to registered callbacks.
      # Must be called regularly on the main thread (e.g. from Godot _process).
      def poll_events : Nil
        events_to_process = Array(QueuedEvent).new

        @mutex.synchronize do
          unless @queue.empty?
            events_to_process.concat(@queue)
            @queue.clear
          end
        end

        events_to_process.each do |ev|
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
            err = ev.error_message || "LibVLC playback error encountered"
            @on_error.try(&.call(err))
          end
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
