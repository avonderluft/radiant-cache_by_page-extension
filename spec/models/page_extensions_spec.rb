require File.dirname(__FILE__) + '/../spec_helper'

describe Page, "with page_options extension" do
  dataset :users_and_pages
  
  before :each do
    @page = pages(:home)
  end
  
  it "should have a 'nocache' attribute set to false by default" do
    @page.nocache?.should == false
  end
  
  it 'should respond to cache? with true (by default)' do
    @page.cache?.should == true
  end
  
  describe  "after updating the 'nocache' attribute to 'true'" do
    
    before :each do
      @page.update_attribute('nocache', true)
    end
  
    it "should have a 'nocache' attribute set to true" do
      @page.nocache?.should == true
    end
  
    it 'should respond to cache? with false' do
      @page.cache?.should == false
    end
  
  end
  
end