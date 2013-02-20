require 'spec_helper'

describe "CacheByPage::PageExtensions" do
  dataset :pages
  
  describe "page with Cache By Page extension" do
    
    before(:each) do
      @page = pages(:home)
    end
    
    it "should have alias method chain set up" do
      @page.should respond_to(:process_without_expire_time)
      @page.should respond_to(:process_with_expire_time)
      @page.should respond_to(:process)
    end
    it "should have class method for default_caching" do
      Page.should respond_to(:default_caching)
    end
    %w{cache_override? cache_duration cache_setting process_with_expire_time}.each do |method|
      it "should have #{method} method" do
        @page.should respond_to(method)
      end
    end
    it "should be valid" do
      @page.should be_valid
    end
    it 'should cache by by default' do
      @page.cache?.should == true
      @page.cache_duration.should == 86400
      @page.cache_setting.should == "1 day"
    end

    describe "- after updates and validation with save" do
      it "should return error if non-numeric is entered for cache_expire_minutes" do
        @page.cache_expire_minutes = "five"
        @page.save.should raise_error
      end
      it "should return error if non-integer is entered for cache_expire_minutes" do
        @page.cache_expire_minutes = "3.3"
        @page.save.should raise_error
      end
      it "should set cache_expire_minutes to 0 when cache_expire_time is updated" do
        @page.update_attribute(:cache_expire_minutes, 30)
        @page.cache_expire_time = 2.days.from_now
        @page.save
        @page.cache_expire_minutes.should == 0
        @page.cache_duration.should be_close(2.days.to_i,2)
        @page.cache_setting.should == "Daily at #{Time.now.strftime('%H:%M')}"
      end
      it "should set cache_expire_time to nil when cache_expire_minutes is updated" do
        @page.update_attribute(:cache_expire_time, 1.day.from_now)
        @page.cache_expire_minutes = 30
        @page.save
        @page.cache_expire_time.should be_nil
        @page.cache_duration.should be_close(30.minutes.to_i,2)
        @page.cache_setting.should == "30 minutes"
      end
      it "should not cache after setting cache_expire_minutes to -1" do
        @page.update_attribute(:cache_expire_minutes, -1)
        @page.cache?.should == false
        @page.cache_duration.should be_nil
        @page.cache_setting.should == "No Caching"
      end

      describe "- updating a page which has caching turned off" do
        before :each do
          @page.update_attribute(:cache_expire_minutes, -1)
          @page.save
        end
        it "should not cache" do
          @page.cache?.should == false
          @page.cache_duration.should be_nil
          @page.cache_setting.should == "No Caching"
        end
        it "should cache after updating cache_expire_minutes" do
          @page.cache_expire_minutes = 30
          @page.save
          @page.cache?.should == true
          @page.cache_duration.should be_close(30.minutes.to_i,2)
          @page.cache_setting.should == "30 minutes"
        end
        it "should cache after updating cache_expire_time" do
          @page.cache_expire_time = 2.days.from_now
          @page.save
          @page.cache?.should == true
          @page.cache_duration.should be_close(2.days.to_i,2)
          @page.cache_setting.should == "Daily at #{Time.now.strftime('%H:%M')}"
        end
      end
    end

  end
  
end