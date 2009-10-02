describe "SyncSpecHelper" do
  it "should test triple helper (tests spec helper method)" do
    expected_triple = {
      "123" => {
        "name" => "value", 
        "other-name" => "other-value"
      } 
    }
    
    triple("123", 
            "name", "value", 
            "other-name", "other-value").should == expected_triple
  end
  
  it "should test triples helper (tests spec helper method)" do 
    expected_triple_hash = {
      "123" => {
        "name1" => "value1"
      },
      "456" => {
        "name2" => "value2"
      },
      "789" => {
        "name3" => "value3", 
        "name4" => "value4"
        
      }
    }
    
    triples( triple("123", "name1", "value1"),
              triple("456", "name2", "value2"),
              triple("789", "name3", "value3", "name4", "value4") ).should == expected_triple_hash
  end
end
