require 'rails_helper'

class DoerOfSomething
  def self.do_something
    'something done by the DoerOfSomething'
  end
end

class DoSomething < GraphQL::Schema::RelayClassicMutation
  field :what_it_did, String

  def authorized?
    true
  end

  def resolve
    puts 'Resolving doSomething mutation'

    result = { what_it_did: DoerOfSomething.do_something }

    puts "Something was done, we'll now return the value!"

    result
  end
end

class RootMutation < GraphQL::Schema::Object
  field :do_something, mutation: DoSomething
end

class TestSchema < GraphQL::Schema
  mutation RootMutation

  use(GraphQL::Dataloader)
end

RSpec.describe 'The bug that happens' do
  subject(:mutation) do
    TestSchema.execute(query, variables: {}, context: {})
  end

  let(:query) do
    <<~GQL
      mutation DoSomething {
        doSomething(input: {}) {
          whatItDid
        }
      }
    GQL
  end

  it 'runs' do
    expect(subject.to_h.dig('data', 'doSomething', 'whatItDid')).to eq 'something done by the DoerOfSomething'
  end

  context 'when I mock DoerOfSomething.do_something' do
    let(:mocked_return_value) { 'the let statement did it!' }

    context 'using #and_return to specify the return value' do
      before do
        allow(DoerOfSomething).to receive(:do_something).and_return(mocked_return_value)
      end

      it 'still runs' do
        expect(subject.to_h.dig('data', 'doSomething', 'whatItDid')).to eq 'the let statement did it!'
      end
    end

    context 'using a block syntax to specify the return value' do
      before do
        allow(DoerOfSomething).to receive(:do_something) do
          puts 'Evaluating mocked_return_value using block_syntax'
          result = mocked_return_value

          puts 'Finished evaluating the let statement for the mocked return value'

          result
        end
      end

      it 'should still run, but it hangs forever when trying to resolve the lazy-evaluated let statement' do
        expect(subject.to_h.dig('data', 'doSomething', 'whatItDid')).to eq 'the let statement did it!'
      end

      context 'but when I use let! instead of the lazy version let' do
        let!(:mocked_return_value) { 'the non-lazy let! statement did it!' }

        it 'runs correctly!' do
          expect(subject.to_h.dig('data', 'doSomething', 'whatItDid')).to eq 'the non-lazy let! statement did it!'
        end
      end
    end
  end
end
