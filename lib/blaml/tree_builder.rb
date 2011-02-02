class Blaml

  class TreeBuilder < Psych::TreeBuilder

    def initialize meta_binding
      @meta_binding = meta_binding
      super()
    end


    ##
    # Sets the @meta instance variable to the metadata
    # matched for the string object.
    # Returns the passed instance.

    def add_meta obj
      obj.meta = @meta_binding.shift_metadata_for obj.value
      obj
    end


    ##
    # Calls parent and applies metadata to return value.

    def scalar value, anchor, tag, plain, quoted, style
      super
      add_meta @last.children.last
    end
  end
end
