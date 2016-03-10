describe 'something' do
  subject { 42 }

  it { is_expected.to eq 42 }

  it 'is a string' do
    pending 'Write this test'
    expect(subject).to be_a String
  end
end
