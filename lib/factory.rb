# frozen_string_literal: true

# * Here you must define your `Factory` class.
# * Each instance of Factory could be stored into variable. The name of this variable is the name of created Class
# * Arguments of creatable Factory instance are fields/attributes of created class
# * The ability to add some methods to this class must be provided while creating a Factory
# * We must have an ability to get/set the value of attribute like [0], ['attribute_name'], [:attribute_name]
#
# * Instance of creatable Factory class should correctly respond to main methods of Struct
# - each
# - each_pair
# - dig
# - size/length
# - members
# - select
# - to_a
# - values_at
# - ==, eql?
# ----------------------------------------------------------------------------
class Factory
  def self.new(*fields, &block)
    raise ArgumentError if fields.empty?

    fields.each do |field|
      next if field.instance_of?(Symbol)

      if field.instance_of?(String) && \
         !field.empty? && \
         field.match(/\A[A-Z]/)

        next
      end

      raise ArgumentError, "identifier #{member} needs to be a constant"
    end

    @identifier = fields.shift if fields.first.instance_of? String

    klass = Class.new do
      attr_accessor(*fields)

      define_method :initialize do |*args|
        raise ArgumentError, 'factory size differs' if fields.size < args.size

        fields.each_with_index do |field, i|
          instance_variable_set "@#{field}", args[i]
        end
      end

      define_method :[] do |accessor|
        check accessor

        if accessor.instance_of? Integer
          return instance_variable_get instance_variables[accessor]
        end

        instance_variable_get "@#{accessor}"
      end

      define_method :[]= do |accessor, value|
        check accessor

        if accessor.instance_of? Integer
          return instance_variable_set instance_variables[accessor], value
        end

        instance_variable_set "@#{accessor}", value
      end

      define_method :members do
        fields
      end

      def ==(other)
        self.class == other.class && values == other.values
      end

      alias_method :eql?, :==

      def each(&block)
        return to_enum unless block_given?

        to_a.each(&block)
      end

      def each_pair(&block)
        return to_enum(method: :each_pair) unless block_given?

        to_h.each_pair(&block)
      end

      def dig(key, *keys)
        return nil unless members.include? key

        return self[key] if keys.empty?

        self[key].dig(*keys)
      end

      def size
        instance_variables.size
      end
      alias_method :length, :size

      def select(&block)
        to_a.select(&block)
      end

      def to_a
        instance_variables.map { |field| instance_variable_get field }
      end
      alias_method :values, :to_a

      def to_h
        members.zip(values).to_h
      end

      def values_at(*ids)
        to_a.values_at(*ids)
      end

      private

      def check(accessor)
        case accessor
        when Integer

          if (instance_variables.size - 1) < accessor
            raise IndexError, "offset #{accessor} is too large \
                              for factory(size:#{instance_variables.size})"
          end

        when String, Symbol

          unless instance_variables.include? "@#{accessor}".to_sym
            raise NameError, "no accessor #{accessor} in factory"
          end

        else raise TypeError, "no implicit convention of \
                              #{accessor.class} into Integer"
        end
      end
    end

    klass.class_eval(&block) if block_given?

    const_set(@identifier, klass) if @identifier

    klass
  end
end
