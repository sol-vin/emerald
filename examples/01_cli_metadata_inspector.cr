require "../src/emerald"

# Standalone multimedia metadata analyzer and stream inspector powered by Emerald
if ARGV.empty?
  puts "Emerald Multimedia Inspector"
  puts "Usage: emerald-inspect <path_or_url>"
  puts ""
  puts "Examples:"
  puts "  emerald-inspect sample.mp4"
  puts "  emerald-inspect https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
  puts "  emerald-inspect https://stream.radioparadise.com/flac"
  exit 0
end

source = ARGV[0]
puts "=" * 70
puts "Emerald Multimedia Inspector"
puts "LibVLC Version:  #{Emerald::VLC::Instance.version}"
puts "LibVLC Compiler: #{Emerald::VLC::Instance.compiler}"
puts "=" * 70

begin
  media = Emerald::VLC::Media.new(source)
  puts "\n[Source]"
  puts "  MRL: #{media.mrl}"

  print "\n[Analyzing Media Streams] ... "
  parsed = media.parse(4000)
  puts parsed ? "Done" : "Partial (Live Stream / Network Timeout)"

  meta = media.metadata
  puts "\n[Metadata]"
  puts "  Duration:   #{meta.formatted_duration} (#{meta.duration_ms} ms)"
  puts "  Title:      #{meta.title || "(none)"}"
  puts "  Artist:     #{meta.artist || "(none)"}"
  puts "  Album:      #{meta.album || "(none)"}"
  puts "  Genre:      #{meta.genre || "(none)"}"
  puts "  Date/Year:  #{meta.date || "(none)"}"
  puts "  Track No:   #{meta.track_number || "(none)"}"
  puts "  Publisher:  #{meta.publisher || "(none)"}"
  puts "  Copyright:  #{meta.copyright || "(none)"}"
  puts "  Cover Art:  #{meta.artwork_url || "(none)"}"

  # Video streams
  video_tracks = media.video_tracks
  puts "\n[Video Streams (#{video_tracks.size})]"
  if video_tracks.empty?
    puts "  (No video streams detected)"
  else
    video_tracks.each do |vt|
      puts "  • [Track #{vt.id}] #{vt.name}: #{vt.resolution} @ #{vt.frame_rate.round(2)} fps (Codec: #{vt.codec})"
    end
  end

  # Audio streams
  audio_tracks = media.audio_tracks
  puts "\n[Audio Streams (#{audio_tracks.size})]"
  if audio_tracks.empty?
    puts "  (No audio streams detected)"
  else
    audio_tracks.each do |at|
      puts "  • [Track #{at.id}] #{at.name}: #{at.channel_layout}, #{at.sample_rate} Hz (Codec: #{at.codec})"
    end
  end

  # Subtitles
  sub_tracks = media.subtitle_tracks
  puts "\n[Subtitle Streams (#{sub_tracks.size})]"
  if sub_tracks.empty?
    puts "  (No subtitle streams detected)"
  else
    sub_tracks.each do |st|
      puts "  • [Track #{st.id}] #{st.name} (Lang: #{st.language || "Unknown"})"
    end
  end

  # Equalizer Presets
  puts "\n[Supported Equalizer Presets (#{Emerald::VLC::Equalizer::PRESETS.size})]"
  puts "  #{Emerald::VLC::Equalizer::PRESETS.join(", ")}"

  puts "\n" + "=" * 70
rescue ex
  STDERR.puts "\nError analyzing media: #{ex.message}"
  exit 1
end
