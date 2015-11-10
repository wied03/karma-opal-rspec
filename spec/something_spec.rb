require 'spec_helper'
require 'sprockets_style'
require 'via_sprockets'

describe 'something' do
  subject { 42 }

  context 'nested' do
    it { is_expected.to eq 42 }
  end

  context 'via sprockets' do
    subject { ViaSprockets.stuff }

    it { is_expected.to eq 22 }
  end
end
