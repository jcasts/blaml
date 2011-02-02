require 'time'
require 'psych'
require 'yaml'

require 'blaml/blamed_io'
require 'blaml/tree_builder'
require 'blaml/meta'
require 'blaml/to_ruby'

class Blaml

  # This gem's version.
  VERSION = "1.0.0"

  ###
  # Load +yaml+ in to a Ruby data structure.  If multiple documents are
  # provided, the object contained in the first document will be returned.
  #
  # Example:
  #
  #   Psych.load("--- a")           # => 'a'
  #   Psych.load("---\n - a\n - b") # => ['a', 'b']

  def self.load yaml
    result = parse(yaml)
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
  # Load the document contained in +filename+.  Returns the yaml contained in
  # +filename+ as a ruby object

  def self.load_file filename
    self.load File.open(filename)
  end


  ###
  # Parse a YAML string in +yaml+.  Returns the first object of a YAML AST.
  #
  # Example:
  #
  #   Psych.parse("---\n - a\n - b") # => #<Psych::Nodes::Sequence:0x00>
  #
  # See Psych::Nodes for more information about YAML AST.

  def self.parse yaml
    children = parse_stream(BlamedIO.new(yaml)).children
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


  class Node

    attr_accessor :value, :meta

    def initialize value, meta
      @value = value
      @meta  = meta
    end
  end
end
