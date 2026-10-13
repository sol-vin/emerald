module Emerald
  module VLC
    # Environment discovery and bootstrapper for LibVLC runtime binaries and plugins.
    module Environment
      class_property? initialized : Bool = false
      class_property custom_vlc_path : String? = nil

      {% if flag?(:windows) %}
        lib Kernel32
          fun SetDllDirectoryA(path_name : LibC::Char*) : LibC::Int
          fun SetEnvironmentVariableA(name : LibC::Char*, value : LibC::Char*) : LibC::Int
          fun LoadLibraryA(lpLibFileName : LibC::Char*) : Void*
          fun GetProcAddress(hModule : Void*, lpProcName : LibC::Char*) : Void*
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

        ["addons/emerald/bin", "bin"].each do |rel|
          expanded = File.expand_path(rel)
          candidates << expanded if File.directory?(expanded)
        end

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

        # Check in Godot project settings if available
        if !Godot::ProjectSettings.singleton_ptr.null?
          ps = Godot::ProjectSettings.new(Godot::ProjectSettings.singleton_ptr)
          addon_plugins = ps.call_str("globalize_path", "res://addons/emerald/bin/plugins").gsub('\\', '/')
          return addon_plugins if File.directory?(addon_plugins)
        end

        search_candidates.each do |dir|
          sub = File.join(dir, "plugins")
          return sub if File.directory?(sub)
        end

        # Check relative to working directory
        ["addons/emerald/bin/plugins", "bin/plugins", "plugins"].each do |rel|
          expanded = File.expand_path(rel)
          return expanded if File.directory?(expanded)
        end

        search_candidates.each do |dir|
          return dir if File.directory?(dir) && File.file?(File.join(dir, "libvlc.dll"))
        end

        nil
      end

      # Bootstraps runtime DLL search and plugin environment variables
      def self.setup! : Nil
        return if @@initialized

        if vlc_dir = find_vlc_directory
          {% if flag?(:windows) %}
            win_vlc_dir = vlc_dir.gsub('/', '\\')
            # Register directory for Windows DLL dynamic loader
            Kernel32.SetDllDirectoryA(win_vlc_dir)

            # Ensure PATH has the directory so dependent DLLs (libvlccore.dll) resolve
            current_path = ENV["PATH"]? || ""
            unless current_path.includes?(win_vlc_dir)
              ENV["PATH"] = "#{win_vlc_dir};#{current_path}"
            end
          {% end %}
        end

        if plugins_dir = find_plugins_directory
          {% if flag?(:windows) %}
            win_plugins_dir = (File.realpath(plugins_dir) rescue plugins_dir).gsub('/', '\\')
            ENV["VLC_PLUGIN_PATH"] ||= win_plugins_dir
            Kernel32.SetEnvironmentVariableA("VLC_PLUGIN_PATH", win_plugins_dir)
            env_entry = "VLC_PLUGIN_PATH=#{win_plugins_dir}"
            {% for dll in ["msvcrt.dll", "ucrtbase.dll"] %}
              h_crt = Kernel32.LoadLibraryA({{dll}})
              unless h_crt.null?
                fn_putenv = Kernel32.GetProcAddress(h_crt, "_putenv")
                unless fn_putenv.null?
                  Proc(LibC::Char*, LibC::Int).new(fn_putenv, Pointer(Void).null).call(env_entry.to_unsafe)
                end
                fn_wputenv = Kernel32.GetProcAddress(h_crt, "_wputenv")
                unless fn_wputenv.null?
                  Proc(UInt16*, LibC::Int).new(fn_wputenv, Pointer(Void).null).call(env_entry.to_utf16.to_unsafe)
                end
              end
            {% end %}
          {% else %}
            ENV["VLC_PLUGIN_PATH"] ||= plugins_dir
          {% end %}
        end

        @@initialized = true
      end
    end
  end
end

# Auto-configure environment upon requiring Emerald
Emerald::VLC::Environment.setup!
