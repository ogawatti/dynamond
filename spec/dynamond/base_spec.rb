require 'spec_helper'

describe Dynamond::Base do
  describe '#initialize' do
    subject { Dynamond::Base.new }
    it { is_expected.to be_instance_of Dynamond::Base }
  end

  describe '.find' do
    context 'with id' do
      #subject { Dynamond::Base.find(1) }
    end
  end
end
