module Emerald
  module VLC
    # Container for extracted media metadata tags, timing, and properties.
    class Metadata
      property title : String?
      property artist : String?
      property album : String?
      property genre : String?
      property date : String?
      property track_number : String?
      property description : String?
      property rating : String?
      property copyright : String?
      property publisher : String?
      property encoded_by : String?
      property artwork_url : String?
      property duration_ms : Int64 = 0_i64

      def initialize(
        @title = nil,
        @artist = nil,
        @album = nil,
        @genre = nil,
        @date = nil,
        @track_number = nil,
        @description = nil,
        @rating = nil,
        @copyright = nil,
        @publisher = nil,
        @encoded_by = nil,
        @artwork_url = nil,
        @duration_ms = 0_i64
      )
      end

      # Duration in floating point seconds
      def duration_seconds : Float64
        @duration_ms / 1000.0
      end

      # Human-friendly duration formatted as HH:MM:SS or MM:SS
      def formatted_duration : String
        total_seconds = @duration_ms // 1000
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        seconds = total_seconds % 60

        if hours > 0
          sprintf("%02d:%02d:%02d", hours, minutes, seconds)
        else
          sprintf("%02d:%02d", minutes, seconds)
        end
      end

      # Returns true if essential media tags are present
      def empty? : Bool
        @title.nil? && @artist.nil? && @album.nil? && @duration_ms == 0_i64
      end

      # Converts metadata fields to a Crystal Hash
      def to_h : Hash(String, String)
        h = Hash(String, String).new
        @title.try { |v| h["title"] = v }
        @artist.try { |v| h["artist"] = v }
        @album.try { |v| h["album"] = v }
        @genre.try { |v| h["genre"] = v }
        @date.try { |v| h["date"] = v }
        @track_number.try { |v| h["track_number"] = v }
        @description.try { |v| h["description"] = v }
        @rating.try { |v| h["rating"] = v }
        @copyright.try { |v| h["copyright"] = v }
        @publisher.try { |v| h["publisher"] = v }
        @artwork_url.try { |v| h["artwork_url"] = v }
        h["duration_ms"] = @duration_ms.to_s
        h["duration"] = formatted_duration
        h
      end

      def to_s(io : IO) : Void
        io << "Metadata("
        parts = Array(String).new
        parts << "title: #{@title.inspect}" if @title
        parts << "artist: #{@artist.inspect}" if @artist
        parts << "album: #{@album.inspect}" if @album
        parts << "duration: #{formatted_duration}" if @duration_ms > 0
        io << parts.join(", ")
        io << ")"
      end
    end
  end
end
