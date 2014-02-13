require 'spec_helper'
require 'deploy'

describe Deploy::Utils do
  context 'symbolize_hash' do
    it 'should convert hash keys to symbols' do
      hash = { 'a' => 1, 'b' => 2 }
      Deploy::Utils.symbolize_hash hash
      hash.should == { :a => 1, :b => 2 }
    end
  end
end



