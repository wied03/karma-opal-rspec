require 'class_under_test'

describe ClassUnderTest do
  describe '::howdy' do
    subject { ClassUnderTest.howdy }

    it { is_expected.to eq 42 }
  end
end
