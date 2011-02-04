require 'time'
require 'psych'
require 'yaml'

require 'blaml/git_blamer'
require 'blaml/blamed_io'
require 'blaml/tree_builder'
require 'blaml/meta'
require 'blaml/to_ruby'

class Blaml

  # This gem's version.
  VERSION = "1.0.0.pre"

  class << self
    # The default blamer interface to use.
    attr_accessor :default_blamer
  end

  self.default_blamer = GitBlamer


  ###
  # Load +yaml+ in to a Ruby data structure.  If multiple documents are
  # provided, the object contained in the first document will be returned.
  #
  # Pass an optional blamer object for blame data parsing
  # (defaults to Blaml.default_blamer).


  def self.load yaml, blamer=nil
    result = parse(yaml, blamer)
    result ? result.to_blamed_ruby : result
  end


  ###
  # Load multiple documents given in +yaml+.  Returns the parsed documents
  # as a list.  For example:
  #
  #   Psych.load_stream("--- foo\n...\n--- bar\n...") # => ['foo', 'bar']
  #
  def self.load_stream yaml
    parse_stream(yaml).children.map { |child| child.to_blamed_ruby }
  end


  ###
  # Load the blamed document contained in +filename+.
  # Returns the yaml contained in +filename+ as a ruby object

  def self.load_file filename
    self.load File.open(filename)
  end


  ##
  # Blame the given file and load the output.
  # Pass an optional blamer object for blame data parsing
  # (defaults to Blaml.default_blamer).

  def self.blame_file filename, blamer=nil
    blamer ||= self.default_blamer
    self.load blamer.blame(filename), blamer
  end


  ###
  # Parse a blamed YAML string in +yaml+.
  # Returns the first object of a YAML AST.
  #
  # Pass an optional blamer object for blame data parsing
  # (defaults to self.default_blamer).

  def self.parse yaml, blamer=nil
    io = BlamedIO.new yaml, blamer

    children = parse_stream(io).children
    children.empty? ? false : children.first.children.first
  end


  ###
  # Parse a file at +filename+. Returns the YAML AST.

  def self.parse_file filename
    File.open filename do |f|
      parse f
    end
  end


  ###
  # Returns a default parser

  def self.parser blaml
    Psych::Parser.new(TreeBuilder.new(blaml))
  end


  ###
  # Parse a YAML blame string in +yaml+.
  # Returns the full AST for the YAML document with blame metadata.
  # See Psych::parse_stream for more info.

  def self.parse_stream blaml
    parser = self.parser blaml
    parser.parse blaml
    parser.handler.root
  end
end
