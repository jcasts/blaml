class Blaml

  ##
  # Subclass Psych's to_ruby to build node values with metadata.

  class ToRuby < Psych::Visitors::ToRuby

    ##
    # Wraps ruby object with MetaNode.
    # See Psych::Visitors::ToRuby

    def visit_Psych_Nodes_Scalar o
      MetaNode.new super, o.meta
    end


    ##
    # Wraps ruby Arrays with MetaArray.
    # See Psych::Visitors::ToRuby

    def visit_Psych_Nodes_Sequence o
      seq  = super
      return seq unless Array === seq

      MetaArray.new seq
    end



    ##
    # Wraps ruby Arrays with MetaHash.
    # See Psych::Visitors::ToRuby

    def visit_Psych_Nodes_Mapping o
      mapp = super
      return mapp unless Hash === mapp

      MetaHash.new mapp
    end
  end
end


class Psych::Nodes::Node

  # Metadata accessor.
  attr_accessor :meta

  ##
  # Tells Psych nodes to use Blaml::ToRuby.

  def to_blamed_ruby
    Blaml::ToRuby.new.accept self
  end
end
