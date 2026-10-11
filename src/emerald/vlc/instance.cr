module Emerald
  module VLC
    # Manages a LibVLC runtime process instance and global settings.
    class Instance
      @@default_instance : Instance?

      getter handle : LibVLC::Instance

      # Default arguments passed to LibVLC for low-latency game engine integration
      DEFAULT_ARGS = [
        "--no-video-title-show",
        "--no-snapshot-preview",
        "--quiet",
        "--network-caching=1000",
        "--sub-source=marq"
      ]

      def initialize(args : Array(String) = DEFAULT_ARGS)
        Environment.setup!

        c_args = args.map(&.to_unsafe)
        @handle = LibVLC.libvlc_new(c_args.size, c_args.to_unsafe)

        if @handle.null?
          err = LibVLC.libvlc_errmsg
          err_str = err.null? ? "Unknown error" : String.new(err)
          raise "Failed to initialize LibVLC instance: #{err_str}"
        end
      end

      # Shared process-wide singleton LibVLC instance
      def self.default : Instance
        @@default_instance ||= new
      end

      # Returns LibVLC version string (e.g. "3.0.23 Vetinari")
      def self.version : String
        ver = LibVLC.libvlc_get_version
        ver.null? ? "Unknown" : String.new(ver)
      end

      # Returns LibVLC compiler information
      def self.compiler : String
        comp = LibVLC.libvlc_get_compiler
        comp.null? ? "Unknown" : String.new(comp)
      end

      # Returns LibVLC changeset string
      def self.changeset : String
        cs = LibVLC.libvlc_get_changeset
        cs.null? ? "Unknown" : String.new(cs)
      end

      # Sets application identification metadata for audio mixers and system notifications
      def set_app_id(id : String, version : String = "1.0", icon : String = "") : Nil
        LibVLC.libvlc_set_app_id(@handle, id, version, icon)
      end

      # Sets HTTP user-agent header for streaming media
      def set_user_agent(name : String, http : String = "") : Nil
        LibVLC.libvlc_set_user_agent(@handle, name, http)
      end

      def finalize
        unless @handle.null?
          LibVLC.libvlc_release(@handle)
          @handle = Pointer(Void).null.as(LibVLC::Instance)
        end
      end
    end
  end
end
