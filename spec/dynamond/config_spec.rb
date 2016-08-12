require 'spec_helper'

describe Dynamond::Config do
  describe '#initialize' do
    subject { Dynamond::Config.new }
    it { is_expected.to be_instance_of Dynamond::Config }
  end
end
