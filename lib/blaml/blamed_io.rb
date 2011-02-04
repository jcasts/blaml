class Blaml

  ##
  # IO wrapper that removes and parses blame data and makes it
  # available as metadata

  class BlamedIO

    # Accessor for currently available metadata.
    attr_reader :metadata

    ##
    # Create new BlamedIO with a string or IO object.
    # Pass an optional blamer object for blame data parsing
    # (defaults to Blaml.default_blamer).

    def initialize io, blamer=nil
      io = StringIO.new io if String === io

      @io        = io
      @metadata  = []
      @meta_mode = true
      @blamer    = blamer || Blaml.default_blamer
    end


    %w{close closed? eof eof? rewind}.each do |meth|
      class_eval "def #{meth}; @io.#{meth}; end"
    end


    ##
    # Retrieves the metadata for a given string that matches
    # the next line in the IO stream and deletes it permanently.

    def shift_metadata_for str
      meta, line = @metadata.first

      if line.nil? || line.empty? || line[0..0] == '#'
        @metadata.shift
        return meta if str.empty?
      end

      meta, line = @metadata.first

      if str.length > line.length

        while str.include? @metadata.first[1] do
          tmp_meta, line = @metadata.shift
          meta = tmp_meta if
            !meta    || !meta[:updated_at]    ||
            meta     && meta[:updated_at]     &&
            tmp_meta && tmp_meta[:updated_at] &&
            tmp_meta[:updated_at] > meta[:updated_at]
        end

      else
        @metadata.first[1] = line.split(str, 2).last.strip
        @metadata.first[1].gsub!(%r{^:(\s+|$)}, "")
      end

      #puts "#{str}  ->  #{meta.inspect}"
      meta
    end


    ##
    # Removes leading spaces and dashes from a line of yaml data.

    def sanitize_data str
      str.to_s.strip.gsub(%r{^(-\s)+}, "")
    end


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
      buffer    = ""
      meta      = nil
      start_pos = @io.pos

      until meta = @blamer.parse(buffer) do

        # Got to the end of line with no metadata.
        # Assume we're reading a regular yml IO.
        if @io.eof? || buffer =~ %r{#{$/}$}
          @io.pos = start_pos
          @metadata << [nil]
          return
        end

        buffer << @io.getc
      end

      @metadata << [meta]

      true
    end
  end
end
