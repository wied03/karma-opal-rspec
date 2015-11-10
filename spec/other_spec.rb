require 'foo'

describe Foo do
  subject { Foo.howdy }

  it { is_expected.to eq 42 }
end
