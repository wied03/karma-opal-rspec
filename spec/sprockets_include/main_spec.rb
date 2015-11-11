require 'sprockets_style'

describe 'something' do
  context 'via sprockets' do
    subject {
      native_val = `window.ViaSprockets`
      native_val
    }

    it { is_expected.to eq 22 }
  end
end
