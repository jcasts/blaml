class Blaml

  ##
  # IO wrapper that removes and parses blame data and makes it
  # available as metadata

  class BlamedIO

    DATE_MATCHER =
      %r{(\d+[-\s:]){6}[^\s]+}

    META_MATCHER =
      %r{([^\s]+)\s+([^\s]+)\s+\(([^\s]+)\s+(#{DATE_MATCHER})\s+(\d+)\)\s}

    # Accessor for currently available metadata.
    attr_reader :metadata


    ##
    # Create new BlamedIO with a string or IO object.

    def initialize io
      io = StringIO.new io if String === io

      @io        = io
      @metadata  = []
      @meta_mode = true
    end


    ##
    # Retrieves the metadata for a given string that matches
    # a line in the IO stream and deletes it permanently.

    def splice_metadata_for str
      selected     = nil
      last_matched = false

      @metadata.each_with_index do |(meta, matcher_str), i|
        last_matched = false and next unless str =~ %r{#{matcher_str}}

        break if selected && !last_matched

        selected = meta if !selected ||
          selected && meta[:updated_at] > selected[:updated_at]

        last_matched = true

        @metadata.delete_at i
        i = i - 1
      end

      selected
    end


    def sanitize_data str
      str.strip.gsub(%r{^(-\s)+}, "")
    end


    ##
    # Close the IO instance.

    def close
      @io.close
    end


    ##
    # Check if IO instance is closed.

    def closed?
      @io.closed?
    end


    ##
    # Returns true if IO instance is at the end of file.

    def eof?
      @io.eof?
    end

    alias eof eof?


    ##
    # Read single char as an integer.

    def getc
      read(1).unpack('c')[0]
    end


    ##
    # Read from the IO instance and parse the blame data.

    def read length=nil, buffer=nil
      buffer  ||= ""
      meta_line = ""

      until buffer.length == length || @io.eof?
        read_meta && @meta_mode = false if @meta_mode

        char = @io.getc
        buffer    << char
        meta_line << char

        if meta_line =~ %r{\w:[\s#{$/}]$}
          str = sanitize_data meta_line.split(%r{:(\s|#{$/})$}, 2).first
          @metadata.last << str
          @metadata << [@metadata.last[0]]
          meta_line = ""

        elsif meta_line =~ %r{#{$/}$}
          @metadata.last << sanitize_data(meta_line.split($/).last)
          meta_line = ""

        end

        @meta_mode = true if buffer[-1..-1] == $/
      end

      buffer
    end


    ##
    # Read a single line.

    def readline sep_string=$/
      buffer = ""
      until buffer[-1..-1] == sep_string || @io.eof?
        buffer << read(1)
      end

      buffer
    end

    alias gets readline


    ##
    # Reads blame metadata.

    def read_meta
      buffer = ""

      start_pos = @io.pos

      until buffer =~ META_MATCHER do

        # Got to the end of line with no metadata.
        # Assume we're reading a regular yml IO.
        if buffer[-1..-1] == $/
          @io.pos = start_pos
          @metadata << [nil]
          return
        end

        buffer << @io.getc
      end

      meta_key = {
        :file       => $2,
        :line       => $6.to_i,
        :author     => $3,
        :commit     => $1,
        :updated_at => Time.parse($4)
      }

      @metadata << [meta_key]

      true
    end


    ##
    # Rewind the IO instance.

    def rewind
      @io.rewind
    end
  end
end
