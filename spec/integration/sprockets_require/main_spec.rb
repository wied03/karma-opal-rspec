require 'sprockets_style'

describe 'something' do
  context 'via sprockets' do
    subject do
      native_val = `window.ViaSprockets`
      native_val
    end

    it { is_expected.to eq 22 }
  end
end
