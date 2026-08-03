require 'rails_helper'

RSpec.describe ApplicationService do
  describe '.call' do
    subject(:service_class) do
      Class.new(described_class) do
        def initialize(value:)
          super()
          @value = value
        end

        def call
          yield(@value)
        end
      end
    end

    it 'passes keyword arguments to the constructor' do
      result = service_class.call(value: 5) { |value| value }

      expect(result).to eq(5)
    end

    it 'passes the block to #call rather than the constructor' do
      result = service_class.call(value: 5) { |value| value * 2 }

      expect(result).to eq(10)
    end
  end
end
