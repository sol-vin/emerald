require "lapis"
require "./media_resource"

# Recognized multimedia extensions supported by LibVLC
EMERALD_MEDIA_EXTENSIONS = [
  "mp4", "mkv", "avi", "webm", "mov", "flv", "ts", "m3u8",
  "ogv", "wmv", "3gp", "mpg", "mpeg", "m4v", "vob",
  "mp3", "wav", "ogg", "flac", "m4a", "aac", "opus", "wma"
]

# Godot ResourceFormatLoader that integrates all LibVLC video/audio formats
# directly into Godot's ResourceLoader and FileSystem dock.
@[Tool]
node ResourceFormatLoaderEmerald < ResourceFormatLoader do
  EXTENSIONS = EMERALD_MEDIA_EXTENSIONS

  @@instance : ResourceFormatLoaderEmerald? = nil
  @@registered : Bool = false
  @@created_by_us : Bool = false

    # Ensures that this resource format loader is registered with Godot's ResourceLoader singleton
    def self.ensure_registered : Void
      return if @@registered

      rl_ptr = Bridge.get_singleton("ResourceLoader")
      if rl_ptr.null?
        return
      end

      r_loader = Godot::ResourceLoader.new(rl_ptr)
      current_type = r_loader.call_str("get_resource_type", "test.mp4")
      if current_type == "EmeraldMediaResource"
        @@registered = true
        @@created_by_us = false
        return
      end

      if loader = Godot.create(ResourceFormatLoaderEmerald)
        @@instance = loader
        @@created_by_us = true
        begin
          r_loader.add_resource_format_loader(loader, true)
        rescue
          r_loader.call("add_resource_format_loader", loader, true) rescue nil
        end
        @@registered = true
        Godot.print("[Emerald] Registered ResourceFormatLoaderEmerald with ResourceLoader")
      else
        Godot.printerr("[Emerald] Failed to create ResourceFormatLoaderEmerald instance")
      end
    end

    # Unregisters this resource format loader from Godot's ResourceLoader singleton
    def self.unregister : Void
      return unless @@registered
      was_creator = @@created_by_us
      loader = @@instance
      @@instance = nil
      @@registered = false
      @@created_by_us = false

      return unless was_creator
      return unless loader && !loader.pointer.null?

      rl_ptr = Bridge.get_singleton("ResourceLoader")
      unless rl_ptr.null?
        r_loader = Godot::ResourceLoader.new(rl_ptr)
        begin
          r_loader.remove_resource_format_loader(loader)
        rescue
          r_loader.call("remove_resource_format_loader", loader) rescue nil
        end
      end

      if loader.alive?
        loader.destroy rescue nil
      end
      loader = nil
      @@instance = nil
    end

    def initialize(pointer : Void* = Pointer(Void).null)
      super(pointer)
    end

    def self._godot_has_virtual_method(method_name : String) : Bool
      norm = method_name.starts_with?('_') ? method_name : "_#{method_name}"
      case norm
      when "_get_recognized_extensions", "_recognize_path", "_handles_type", "_get_resource_type", "_get_resource_script_class", "_get_resource_uid", "_exists", "_load"
        true
      else
        false
      end
    end

    def _godot_call_virtual_with_data(method_name : String, args : Void**, ret : Void*) : Void
      norm = method_name.starts_with?('_') ? method_name : "_#{method_name}"
      case norm
      when "_get_recognized_extensions"
        Bridge.ret_packed_string_array(ret, EXTENSIONS)
      when "_recognize_path"
        path = (args && args[0]) ? Bridge.arg_to_string(args[0]) : ""
        tname = ""
        if args && args[1]
          tname = Bridge.arg_to_string_name(args[1]) rescue ""
          tname = Bridge.arg_to_string(args[1]) rescue "" if tname.empty?
        end
        type_ok = tname.empty? || tname == "Resource" || tname == "EmeraldMediaResource" || tname == "VideoStream"
        ext = path.downcase.split('.').last? || ""
        ret.as(UInt8*).value = (type_ok && EXTENSIONS.includes?(ext)) ? 1_u8 : 0_u8
      when "_handles_type"
        typename = (args && args[0]) ? (Bridge.arg_to_string_name(args[0]) rescue "") : ""
        typename = Bridge.arg_to_string(args[0]) rescue "" if typename.empty? && args && args[0]
        handles = (typename == "Resource" || typename == "EmeraldMediaResource" || typename == "VideoStream" || typename.empty?)
        ret.as(UInt8*).value = handles ? 1_u8 : 0_u8
      when "_get_resource_type"
        path = (args && args[0]) ? Bridge.arg_to_string(args[0]) : ""
        ext = path.downcase.split('.').last? || ""
        Bridge.ret_string(ret, EXTENSIONS.includes?(ext) ? "EmeraldMediaResource" : "")
      when "_get_resource_script_class"
        Bridge.ret_string(ret, "")
      when "_get_resource_uid"
        ret.as(Int64*).value = -1_i64
      when "_exists"
        path = (args && args[0]) ? Bridge.arg_to_string(args[0]) : ""
        resolved = Emerald.resolve_source_path(path)
        ret.as(UInt8*).value = File.file?(resolved) ? 1_u8 : 0_u8
      when "_load"
        path = (args && args[0]) ? Bridge.arg_to_string(args[0]) : ""
        orig_path = (args && args[1]) ? Bridge.arg_to_string(args[1]) : ""
        target_path = orig_path.empty? ? path : orig_path

        res = Godot.create(EmeraldMediaResource)
        if res
          res.file_path = target_path
          res.populate_metadata!
          Bridge.ret_variant_object(ret, res.pointer)
        else
          Bridge.ret_variant_nil(ret)
        end
      else
        super
      end
    end
  end

module Emerald
  EXTENSIONS = EMERALD_MEDIA_EXTENSIONS
  alias ResourceFormatLoader = ::ResourceFormatLoaderEmerald
  alias ResourceFormatLoaderEmerald = ::ResourceFormatLoaderEmerald
end
