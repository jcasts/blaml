class Blaml

  ##
  # Subclass Psych's to_ruby to build node values with metadata.

  class ToRuby < Psych::Visitors::ToRuby

    ##
    # Assign the given meta data to the object and return the
    # given object.

    def add_meta obj, meta
      case obj
      when Array then MetaArray.new obj, meta
      when Hash  then MetaHash.new obj, meta
      else
        MetaNode.new obj, meta
      end
    end


    def visit_Psych_Nodes_Scalar o
      MetaNode.new super, o.meta
    end


    def visit_Psych_Nodes_Sequence o
      seq  = super
      return seq unless Array === seq

      MetaArray.new seq
    end


    def visit_Psych_Nodes_Mapping o
      mapp = super
      return mapp unless Hash === mapp

      MetaHash.new mapp
    end
  end
end


class Psych::Nodes::Node
  attr_accessor :meta

  def to_blamed_ruby
    Blaml::ToRuby.new.accept self
  end
end
