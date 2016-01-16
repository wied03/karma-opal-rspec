RSpec.configure do |c|
  c.filter_run_including focus: true
end

describe 'something' do
  subject { 42 }

  fit { is_expected.to eq 42 }
end

describe 'else' do
  subject { 43 }

  it { is_expected.to eq 42 }
end
