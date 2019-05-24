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
    identifier, *rest = fields

    if constant?(identifier)
      return const_set(identifier, create_class(*rest, &block))
    end

    if identifier.is_a? String
      raise ArgumentError, "identifier #{identifier} needs to be a constant"
    end

    create_class(*fields, &block)
  end

  def self.constant?(value)
    value.instance_of?(String) && \
      value.strip.match?(/\A[A-Z]/)
  end

  def self.create_class(*fields, &block)
    Class.new do
      attr_accessor(*fields)

      define_method :initialize do |*args|
        raise ArgumentError, 'factory size differs' if fields.size < args.size

        fields.zip(args).each do |field_value|
          instance_variable_set "@#{field_value[0]}", field_value[1]
        end
      end

      define_method :[] do |accessor|
        if accessor.instance_of? Integer
          return instance_variable_get instance_variables[accessor]
        end

        instance_variable_get "@#{accessor}"
      end

      define_method :[]= do |accessor, value|
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
        values.each(&block)
      end

      def each_pair(&block)
        members.zip(values).each(&block)
      end

      def dig(*keys)
        keys.inject(self) { |values, key| values[key] if values }
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
        values.select { |value| ids.include?(values.index(value)) }
      end

      class_eval(&block) if block_given?
    end
  end
end