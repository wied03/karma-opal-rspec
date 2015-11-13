require 'foo'

describe Foo do
  subject { Foo.howdy }

  context 'nested' do
    it { is_expected.to eq 42 }
  end
end
