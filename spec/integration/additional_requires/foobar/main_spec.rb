require 'browser'

describe 'document' do
  # it's not our global var
  # rubocop:disable Style/GlobalVars
  subject { $document }
  # rubocop:enable Style/GlobalVars

  it { is_expected.to respond_to :body }
end
