require 'bar'
require 'foo'
require 'foo'

describe Bar do
  subject { Bar.howdy }

  it { is_expected.to eq 42 }
end
