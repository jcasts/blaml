class Blaml

  ##
  # The interface for git repo interaction.
  # Write your own for other scm tools!

  class GitBlamer

    DATE_MATCHER =
      %r{(\d+[-\s:]){6}[^\s]+}

    META_MATCHER =
      %r{([^\s]+)\s+([^\s]+)\s+\(([^\s]+)\s+(#{DATE_MATCHER})\s+(\d+)\)\s}


    ##
    # Returns the blamed contents of the given file.

    def self.blame filepath
      filepath, filename = File.split filepath

      blame_str = `cd #{filepath} && git blame -f #{filename}`
      raise blame_str unless $?.success?

      blame_str
    end


    ##
    # Parses the given string for blame data, returns a hash with blame data
    # or nil if unparsable.
    #
    # Hash keys returned are:
    # :file:: String - The filepath
    # :line:: Integer - The line this data came from
    # :author:: String - The username of the author of the change
    # :commit:: String - The revision identifier of the commit
    # :updated_at:: Time - The time when the commit was made

    def self.parse str
      return unless str =~ META_MATCHER

      {
        :file       => $2,
        :line       => $6.to_i,
        :author     => $3,
        :commit     => $1,
        :updated_at => Time.parse($4)
      }
    end
  end
end
