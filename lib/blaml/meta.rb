class Blaml

  class MetaNode

    attr_reader :value
    attr_writer :meta

    def initialize value, meta=nil
      @value = value
      @meta  = meta
    end


    def == obj
      case obj
      when MetaNode then obj.value == @value
      else
        @value == obj
      end
    end


    def meta
      @meta
    end


    %w{to_s to_i to_f to_sym inspect}.each do |meth|
      class_eval "def #{meth}; @value.#{meth}; end"
    end


    def method_missing name, *args, &block
      @value.send name, *args, &block
    end


    def to_value
      @value
    end
  end


  class MetaArray < MetaNode

    def meta
      meta = nil

      @value.each do |val|
        next unless val.respond_to? :meta

        meta = val.meta if !meta ||
          meta && val.meta && val.meta[:updated_at] > meta[:updated_at]
      end

      meta
    end


    def to_value
      @value.map{|v| v.respond_to?(:to_value) ? v.to_value : v }
    end
  end


  class MetaHash < MetaNode
    def [] key
      @value.each{|k,v| return v if k == key}
    end


    def []= key, val
      @value.each{|k,v| @value[k] = val and return if k == key}
    end


    def merge! hash
      hash.each do |k,v|
        key = @value.keys.find{|vk| vk == k || k == vk } || k
        @value.delete key
        @value[k] = v
      end

      self
    end


    def merge hash
      clone = @value.dup
      hash.each do |k,v|
        key = clone.keys.find{|vk| vk == k || k == vk } || k
        clone.delete key
        clone[k] = v
      end

      clone
    end


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
