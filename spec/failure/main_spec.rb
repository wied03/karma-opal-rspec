describe 'something' do
  subject { 42 }

  context 'failure' do
    it { is_expected.to eq 43 }
  end
end
