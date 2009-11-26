require File.join(File.dirname(__FILE__),'spec_helper')
$:.unshift File.join(__FILE__,'..','lib')
require 'rhosync_store'

describe "Protocol" do
  it_should_behave_like "RhosyncStoreDataHelper"
  

  
end