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
  def self.new(*members, &block)
    # --- Members validation ---
    raise ArgumentError if members.empty?

    members.each do |member|
      next if member.instance_of?(Symbol)

      next if member.instance_of?(String) && !member.empty? && member.match(/\A[A-Z]/)

      raise ArgumentError, "identifier #{member} needs to be a constant"
    end

    # Classname validation and setup
    @identifier = members.shift if members.first.instance_of? String

    klass = Class.new do
      # --- Struct setup ---
      define_method :initialize do |*args|
        raise ArgumentError, 'factory size differs' if members.size < args.size

        members.each_with_index do |member, i|
          # Set Struct fields
          instance_variable_set "@#{member}", args[i]

          # Set read accessor for each field
          define_singleton_method member.to_s do
            instance_variable_get "@#{member}"
          end

          # Set write accessor for each field
          define_singleton_method "#{member}=" do |val|
            instance_variable_set "@#{member}", val
          end
        end
      end

      # Bracket GET method
      define_method :[] do |member|
        accessor_valid? member

        return instance_variable_get instance_variables[member] if member.instance_of? Integer

        instance_variable_get "@#{member}"
      end

      # Bracket SET method
      define_method :[]= do |member, val|
        accessor_valid? member

        return instance_variable_set instance_variables[member], val if member.instance_of? Integer

        instance_variable_set "@#{member}", val
      end

      # --- Struct methods ---

      define_method :members do
        members
      end

      def ==(other)
        self.class == other.class && instance_variables.all? do |member|
          instance_variable_get(member) == other.instance_variable_get(member)
        end
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
        instance_variables.map { |x| instance_variable_get x }
      end
      alias_method :values, :to_a

      def to_h
        members.each_with_object({}) { |v, h| h[v] = instance_variable_get "@#{v}" }
      end

      def values_at(*ids)
        to_a.values_at(*ids)
      end

      private

      def accessor_valid?(accessor)
        case accessor
        when Integer
          if (instance_variables.size - 1) < accessor
            raise IndexError, "offset #{accessor} is too large for factory(size:#{instance_variables.size})"
          end

          true
        when String, Symbol
          if !instance_variables.include? "@#{accessor}".to_sym
            raise NameError, "no member #{accessor} in factory"
          end

          true
        else raise TypeError, "no implicit convention of #{accessor.class} into Integer"
        end
      end
    end

    klass.class_eval(&block) if block_given?

    const_set(@identifier, klass) if @identifier

    klass
  end
end
