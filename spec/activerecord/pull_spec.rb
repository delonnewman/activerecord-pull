RSpec.describe ActiveRecord::Pull::Alpha::Core do
  let(:attributes) { { first_name: 'John-Jacob', last_name: 'Jingleheimer-Schmit', age: 34 } }
  let(:record) { Person.new { |p| p.attributes = attributes } }

  describe '#pull' do
    context 'when a symbol attribute name is the query' do
      it "will return a hash with that key and it's value selected" do
        expect(described_class.pull(record, :first_name)).to eq({ first_name: 'John-Jacob' })
      end
    end

    context 'when a string attribute name is the query' do
      it "will return a hash with that key and it's value selected" do
        expect(described_class.pull(record, 'first_name')).to eq({ first_name: 'John-Jacob' })
      end
    end

    context 'when a missing attribute name is the query' do
      it "will return an empty hash" do
        expect(described_class.pull(record, :middle_name)).to be_empty
      end
    end

    context 'when :* or "*" is the query' do
      it 'will return a hash with all the keys and values in the record' do
        expect(described_class.pull(record, :*)).to eq(attributes)
      end
    end

    context 'when query is an array of attribute names' do
      let(:data) { described_class.pull(record, attribute_names) }

      let(:attribute_names) { %i[first_name last_name] }

      it 'will return a hash with the keys and values in the record' do
        expect(data).to eq({ first_name: 'John-Jacob', last_name: 'Jingleheimer-Schmit' })
      end

      context 'when extra attributes are included' do
        let(:attribute_names) { %i[first_name last_name middle_name] }

        it 'will ignore extra attribute names' do
          expect(data).to eq({ first_name: 'John-Jacob', last_name: 'Jingleheimer-Schmit' })
        end
      end
    end
  end
end
