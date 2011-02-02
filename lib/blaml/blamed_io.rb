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
    # the next line in the IO stream and deletes it permanently.

    def shift_metadata_for str
      meta, line = @metadata.first

      if line.nil? || line.empty?
        @metadata.shift
        return meta if str.empty?
      end

      meta, line = @metadata.first

      if str.length > line.length
        begin
          meta, line = @metadata.shift
        end while str.include? @metadata.first[1]
      else
        @metadata.first[1] = line.split(str, 2).last.strip
      end

      meta
    end


    def sanitize_data str
      str.to_s.strip.gsub(%r{^(-\s)+}, "")
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
        if @meta_mode
          read_meta
          @meta_mode = false
        end

        char = @io.getc
        buffer    << char
        meta_line << char

        if buffer[-1..-1] == $/
          @meta_mode = true
          @metadata.last << sanitize_data(meta_line)
          meta_line = ""
        end
      end

      #puts @metadata.map{|i| i.inspect}.join("\n")
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
        if @io.eof? || buffer =~ %r{#{$/}$}
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
