module Emerald
  module VLC
    # Environment discovery and bootstrapper for LibVLC runtime binaries and plugins.
    module Environment
      class_property? initialized : Bool = false
      class_property custom_vlc_path : String? = nil

      {% if flag?(:windows) %}
        lib Kernel32
          fun SetDllDirectoryA(path_name : LibC::Char*) : LibC::Int
        end
      {% end %}

      # Standard directories where VLC is commonly installed
      def self.search_candidates : Array(String)
        candidates = Array(String).new
        if custom = @@custom_vlc_path
          candidates << custom
        end

        if env_vlc = ENV["VLC_PATH"]?
          candidates << env_vlc
        end

        {% if flag?(:windows) %}
          candidates << "C:\\Program Files\\VideoLAN\\VLC"
          candidates << "C:\\Program Files (x86)\\VideoLAN\\VLC"
        {% elsif flag?(:darwin) %}
          candidates << "/Applications/VLC.app/Contents/MacOS"
        {% else %}
          candidates << "/usr/lib/vlc"
          candidates << "/usr/lib/x86_64-linux-gnu/vlc"
          candidates << "/usr/local/lib/vlc"
        {% end %}

        candidates
      end

      # Finds the base directory containing libvlc
      def self.find_vlc_directory : String?
        search_candidates.find do |dir|
          {% if flag?(:windows) %}
            File.file?(File.join(dir, "libvlc.dll"))
          {% elsif flag?(:darwin) %}
            File.file?(File.join(dir, "lib", "libvlc.dylib")) || File.file?(File.join(dir, "libvlc.dylib"))
          {% else %}
            File.file?(File.join(dir, "libvlc.so")) || File.directory?(File.join(dir, "plugins"))
          {% end %}
        end
      end

      # Finds the VLC plugins directory
      def self.find_plugins_directory : String?
        if env_plugins = ENV["VLC_PLUGIN_PATH"]?
          return env_plugins if File.directory?(env_plugins)
        end

        if vlc_dir = find_vlc_directory
          sub = File.join(vlc_dir, "plugins")
          return sub if File.directory?(sub)
          return vlc_dir if File.directory?(vlc_dir)
        end

        nil
      end

      # Bootstraps runtime DLL search and plugin environment variables
      def self.setup! : Nil
        return if @@initialized

        if vlc_dir = find_vlc_directory
          {% if flag?(:windows) %}
            # Register directory for Windows DLL dynamic loader
            Kernel32.SetDllDirectoryA(vlc_dir)

            # Ensure PATH has the directory so dependent DLLs (libvlccore.dll) resolve
            current_path = ENV["PATH"]? || ""
            unless current_path.includes?(vlc_dir)
              ENV["PATH"] = "#{vlc_dir};#{current_path}"
            end
          {% end %}
        end

        if plugins_dir = find_plugins_directory
          ENV["VLC_PLUGIN_PATH"] ||= plugins_dir
        end

        @@initialized = true
      end
    end
  end
end

# Auto-configure environment upon requiring Emerald
Emerald::VLC::Environment.setup!
