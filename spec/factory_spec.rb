# frozen_string_literal: true

require_relative '../lib/factory'

RSpec.describe 'Factory' do
  before do
    if Object.constants.include?(:Customer)
      Object.send(:remove_const, :Customer)
    end
  end

  it 'creates factory in a namespace' do
    Factory.new('Customer', :name, :address)

    customer = Factory::Customer.new('Dave', '123 Main')

    expect(customer.name).to eq('Dave')
    expect(customer.address).to eq('123 Main')
  end

  it 'creates standalone class' do
    Customer = Factory.new(:name, :address) do
      def greeting
        "Hello #{name}!"
      end
    end

    customer = Customer.new('Dave', '123 Main')

    expect(customer.greeting).to eq('Hello Dave!')
  end

  it 'raises ArgumentError when extra args passed' do
    Customer = Factory.new(:name, :address) do
      def greeting
        "Hello #{name}!"
      end
    end

    expect { Customer.new('Dave', '123 Main', 123) }.to raise_error(ArgumentError)
  end

  it 'equality operator works as expected' do
    Customer = Factory.new(:name, :address, :zip)

    joe = Customer.new('Joe Smith', '123 Maple, Anytown NC', 12_345)
    joejr = Customer.new('Joe Smith', '123 Maple, Anytown NC', 12_345)

    jane = Customer.new('Jane Doe', '456 Elm, Anytown NC', 12_345)

    expect(joe).to eq(joejr)
    expect(joe).not_to eq(jane)
  end

  it 'attribute reference operator works as expected' do
    Customer = Factory.new(:name, :address, :zip)

    joe = Customer.new('Joe Smith', '123 Maple, Anytown NC', 12_345)

    expect(joe['name']).to eq('Joe Smith')
    expect(joe[:name]).to eq('Joe Smith')
    expect(joe[0]).to eq('Joe Smith')
  end

  it 'attribute assignment operator works as expected' do
    Customer = Factory.new(:name, :address, :zip)

    joe = Customer.new('Joe Smith', '123 Maple, Anytown NC', 12_345)

    joe['name'] = 'Luke'
    joe[:zip]   = '90210'

    expect(joe.name).to eq('Luke')
    expect(joe.zip).to eq('90210')
  end

  it 'dig works as expected' do
    Customer = Factory.new(:a)

    c = Customer.new(Customer.new(b: [1, 2, 3]))

    expect(c.dig(:a, :a, :b, 0)).to eq(1)
    expect(c.dig(:b, 0)).to be_nil

    expect { c.dig(:a, :a, :b, :c) }.to raise_error(TypeError)
  end

  it 'each works as expected' do
    Customer = Factory.new(:name, :address, :zip)

    joe = Customer.new('Joe Smith', '123 Maple, Anytown NC', 12_345)

    each_elements = []

    joe.each { |x| each_elements << x }

    expect(each_elements).to match_array(['Joe Smith', '123 Maple, Anytown NC', 12_345])
  end

  it 'each_pair works as expected' do
    Customer = Factory.new(:name, :address, :zip)

    joe = Customer.new('Joe Smith', '123 Maple, Anytown NC', 12_345)

    each_elements = []

    joe.each_pair { |name, value| each_elements << "#{name} => #{value}" }

    expect(each_elements).to match_array(['name => Joe Smith', 'address => 123 Maple, Anytown NC', 'zip => 12345'])
  end

  it 'length (size) works as expected' do
    Customer = Factory.new(:name, :address, :zip)

    joe = Customer.new('Joe Smith', '123 Maple, Anytown NC', 12_345)

    expect(joe.length).to eq(3)
    expect(joe.size).to eq(3)
  end

  it 'members works as expected' do
    Customer = Factory.new(:name, :address, :zip)

    joe = Customer.new('Joe Smith', '123 Maple, Anytown NC', 12_345)

    expect(joe.members).to match_array(%i[name address zip])
  end

  it 'selects works as expected' do
    Customer = Factory.new(:a, :b, :c, :d, :e, :f)

    l = Customer.new(11, 22, 33, 44, 55, 66)

    result = l.select(&:even?)

    expect(result).to match_array([22, 44, 66])
  end

  it 'to_a works as expected' do
    Customer = Factory.new(:name, :address, :zip)

    joe = Customer.new('Joe Smith', '123 Maple, Anytown NC', 12_345)

    expect(joe.to_a[1]).to eq('123 Maple, Anytown NC')
  end

  it 'values_at works as expected' do
    Customer = Factory.new(:name, :address, :zip)

    joe = Customer.new('Joe Smith', '123 Maple, Anytown NC', 12_345)

    expect(joe.values_at(0, 2)).to eq(['Joe Smith', 12_345])
  end
end
