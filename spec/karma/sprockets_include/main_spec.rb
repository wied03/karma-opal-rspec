require 'sprockets_style'
require 'via_sprockets'

describe 'something' do
  context 'via sprockets' do
    subject { ViaSprockets.stuff }

    it { is_expected.to eq 22 }
  end
end
