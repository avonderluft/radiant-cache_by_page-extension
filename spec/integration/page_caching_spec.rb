require File.dirname(__FILE__) + '/../spec_helper'

describe Page, "with page-specific caching", :type => :integration do
  dataset :pages

  before :all do
    @cache_dir = "#{RAILS_ROOT}/tmp/cache"
    @cache_file = "#{@cache_dir}/_site-root.yml"
  end

  before :each do
    @page = pages(:home)
    ResponseCache.defaults[:directory] = @cache_dir
    ResponseCache.defaults[:perform_caching] = true
    ResponseCache.defaults[:expire_time] = 1.day
    @cache = ResponseCache.instance
    @cache.clear if @cache.defaults[:directory] == @cache_dir # prevents rm -rf / !
  end

  it "should be valid" do
    @page.should be_valid
  end
  it "should have alias method chain set up" do
    @page.should respond_to(:process_without_expire_time)
    @page.should respond_to(:process_with_expire_time)
    @page.should respond_to(:process)
  end

  describe "- intial fetch of page before updates" do
    it "should have valid cache_expire_minutes" do
      @page.cache_expire_minutes.should be_instance_of(Fixnum)
      @page.should have(:no).errors_on(:cache_expire_minutes)
    end
    it do
      @page.should have(:no).errors_on(:cache_expire_time)
    end
    it 'should cache by by default' do
      @page.cache?.should == true
    end
    it "should render a page with default caching" do
      navigate_to "#{@page.slug}"
      response.should be_success
      response.cache_timeout.should be_nil
      @cache.response_cached?(@page.url).should be_true
    end
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
      @page.cache_expire_time = 1.day.from_now
      @page.save
      @page.cache_expire_minutes.should == 0
    end
    it "should set cache_expire_time to nil when cache_expire_minutes is updated" do
      @page.update_attribute(:cache_expire_time, 1.day.from_now)
      @page.cache_expire_minutes = 30
      @page.save
      @page.cache_expire_time.should be_nil
    end
    it "should not cache after setting cache_expire_minutes to -1" do
      @page.update_attribute(:cache_expire_minutes, -1)
      @page.cache?.should == false
    end

    describe "- updating a page which has caching turned off" do
      before :each do
        @page.update_attribute(:cache_expire_minutes, -1)
        @page.cache?.should == false
      end
      it "should cache after updating cache_expire_minutes" do
        @page.cache_expire_minutes = 30
        @page.save
        @page.cache?.should == true
      end
      it "should cache after updating cache_expire_time" do
        @page.cache_expire_time = 1.day.from_now
        @page.save
        @page.cache?.should == true
      end
    end
  end

  describe "- setting page specific caching with number of minutes" do
    before :each do
      @cache.response_cached?(@page.url).should be_false
      @expire_mins = 30
      @page.cache_expire_minutes = @expire_mins
      @page.save
      navigate_to "#{@page.slug}"
    end
    it "should have cached the page" do
      @cache.response_cached?(@page.url).should be_true
    end
    it "should set the cache_timeout after updating cache_expire_minutes" do
      response.should_receive(:cache_timeout=){|timeout| timeout.should be_close(@expire_mins.minutes.from_now, 1) }
      @page.process(request, response)
    end
    it "should cache page for the specified time" do
      YAML.load_file(@cache_file)['expires'].should be_close(@expire_mins.minutes.from_now, 1)
    end
    it "should re-cache the page if the expire_time is past" do
      yf = YAML.load_file(@cache_file)
      yf['expires'] = Time.now.yesterday
      FileUtils.rm(@cache_file)
      File.open(@cache_file, 'w') { |f| f.write(yf.to_yaml) }
      YAML.load_file(@cache_file)['expires'].should be_close(Time.now.yesterday, 60)
      navigate_to "#{@page.slug}"
      YAML.load_file(@cache_file)['expires'].should be_close(@expire_mins.minutes.from_now, 60)
    end
  end
  describe "- setting page specific caching with specific time of day" do
    before :each do
      @cache.response_cached?(@page.url).should be_false
      @expire_time = 3.hours.from_now
      @page.cache_expire_time = @expire_time
      @page.save
      navigate_to "#{@page.slug}"
    end
    it "should have cached the page" do
      @cache.response_cached?(@page.url).should be_true
    end
    it "should set the cache_timeout after updating cache_expire_time" do
      response.should_receive(:cache_timeout=){|timeout| timeout.should be_close(@expire_time, 60) }
      @page.process(request, response)
    end
    it "should cache page for the specified time" do
      YAML.load_file(@cache_file)['expires'].should be_close(@expire_time, 60)
    end
    it "should re-cache the page if the expire_time is past" do
      yf = YAML.load_file(@cache_file)
      yf['expires'] = Time.now.yesterday
      FileUtils.rm(@cache_file)
      File.open(@cache_file, 'w') {|f| f.write(yf.to_yaml) }
      YAML.load_file(@cache_file)['expires'].should be_close(Time.now.yesterday, 60)
      navigate_to "#{@page.slug}"
      YAML.load_file(@cache_file)['expires'].should be_close(@expire_time, 60)
    end
  end

end
