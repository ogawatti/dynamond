require 'spec_helper'

describe Dynamond::Migration do
  describe '#initialize' do
    subject { Dynamond::Migration.new }
    it { is_expected.to be_instance_of Dynamond::Migration }
  end
end
