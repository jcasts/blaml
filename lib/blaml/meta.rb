class Blaml


  ##
  # Simple wrapper class to assign metadata to object instances.

  class MetaNode


    # The object to assign metadata to.
    attr_reader :value

    # The metadata assigned to the wrapped object.
    attr_writer :meta

    ##
    # Create a new MetaNode with the value to wrap and optional metadata.

    def initialize value, meta=nil
      @value = value
      @meta  = meta
    end


    ##
    # Checks for equality against the value attribute.

    def == obj
      case obj
      when MetaNode then obj.value == @value
      else
        @value == obj
      end
    end


    ##
    # Accessor for the meta attribute.
    # Overridden in MetaArray and MetaHash classes.

    def meta
      @meta
    end


    %w{to_s to_i to_f to_sym inspect}.each do |meth|
      class_eval "def #{meth}; @value.#{meth}; end"
    end


    ##
    # Sends non-defined methods to the value attribute

    def method_missing name, *args, &block
      @value.send name, *args, &block
    end


    ##
    # Accessor for the value attribute.
    # Overridden in MetaArray and MetaHash classes.

    def to_value
      @value
    end
  end


  ##
  # Wraps Array instances with metadata.

  class MetaArray < MetaNode

    ##
    # Returns the child metadata with the most recent change.

    def meta
      meta = nil

      @value.each do |val|
        next unless val.respond_to? :meta

        meta = val.meta if !meta ||
          meta && val.meta && val.meta[:updated_at] > meta[:updated_at]
      end

      meta
    end


    ##
    # Strips MetaNode wrapper from the value and calls to_value
    # on all array elements.

    def to_value
      @value.map{|v| v.respond_to?(:to_value) ? v.to_value : v }
    end
  end


  ##
  # Wraps Hash instances with metadata.

  class MetaHash < MetaNode

    ##
    # Access a value of the wrapped hash.

    def [] key
      @value.each{|k,v| return v if k == key}
    end


    ##
    # Assign a value of the wrapped hash.

    def []= key, val
      @value.each{|k,v| @value[k] = val and return if k == key}
    end


    ##
    # Merge with and modify the wrapped hash.

    def merge! hash
      hash.each do |k,v|
        key = @value.keys.find{|vk| vk == k || k == vk } || k
        @value.delete key
        @value[k] = v
      end

      self
    end


    ##
    # Create a new MetaHash merged with the given hash or metahash.

    def merge hash
      clone = @value.dup
      hash.each do |k,v|
        key = clone.keys.find{|vk| vk == k || k == vk } || k
        clone.delete key
        clone[k] = v
      end

      clone
    end


    ##
    # Returns the child metadata with the most recent change.

    def meta
      meta = nil

      @value.each do |key, val|
        if val.respond_to? :meta
          meta = val.meta if !meta ||
            meta && val.meta && val.meta[:updated_at] > meta[:updated_at]
        end

        if key.respond_to? :meta
          meta = key.meta if !meta ||
            meta && val.meta && key.meta[:updated_at] > meta[:updated_at]
        end
      end

      meta
    end


    ##
    # Strips MetaNode wrapper from the value and calls to_value
    # on all hash elements.

    def to_value
      clone = Hash.new

      @value.each do |k, v|
        key = k.respond_to?(:to_value) ? k.to_value : k
        val = v.respond_to?(:to_value) ? v.to_value : v

        clone[key] = val
      end

      clone
    end
  end
end
