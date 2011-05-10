require File.dirname(__FILE__) + '/../spec_helper'

describe Page, "with page-specific caching", :type => :integration do
  dataset :pages
  USING_RACK_CACHE = SiteController.respond_to?('cache_timeout')

  before :all do
    FileUtils.chdir RAILS_ROOT
    @cache_dir = "#{RAILS_ROOT}/tmp/cache"
    @cache_file = USING_RACK_CACHE ? "#{@cache_dir}/meta/*/*" : "#{@cache_dir}/_site-root.yml"
  end

  before :each do
    @page = pages(:home)
    @default = 1.day
    if USING_RACK_CACHE
      SiteController.page_cache_directory = @cache_dir
      SiteController.perform_caching = true
      SiteController.cache_timeout = @default
    else
      ResponseCache.defaults[:directory] = @cache_dir
      ResponseCache.defaults[:perform_caching] = true
      ResponseCache.defaults[:expire_time] = @default
    end
    @expire_mins = @default.to_i/60
    @cache = USING_RACK_CACHE ? Radiant::Cache : ResponseCache.instance
    @cache.clear
  end

  def page_is_cached(page)
    if response.nil?
      @cache.clear
      false
    elsif USING_RACK_CACHE
      ! response.headers['Cache-Control'].include?('no-cache')
    else
      @cache.response_cached?(page.url)
    end
  end

  def cache_expires
    if USING_RACK_CACHE
      Time.now + `cat #{@cache_file}`.split('max-age=')[1].split(',')[0].to_i rescue nil
    else
      YAML.load_file(@cache_file)['expires'] rescue nil
    end
  end

  describe "- intial fetch of page before updates" do
    it "should render a page with default caching" do
      get "#{@page.slug}"
      response.should be_success
      response.cache_timeout.should be_nil
      page_is_cached(@page).should be_true
      if USING_RACK_CACHE
        response.headers['Cache-Control'].should == "max-age=#{@default}, public"
      else
        @cache.expire_time.should == @default
        @cache.response_cached?(@page.url).should be_true
      end
    end
  end

  %w(minutes time).each do |att|
    describe "- page with specific caching option by #{att}" do

      before(:each) do
        @cache.clear
        page_is_cached(@page).should be_false
        @expire_mins = 180
        @expire_time = @expire_mins.minutes.from_now
        if att == "minutes"
          @page.cache_expire_minutes = @expire_mins
        elsif att == "time"
          @page.cache_expire_time = @expire_time
        end
        @page.save!
        get "#{@page.slug}"
        page_is_cached(@page).should be_true
      end

      it "should cache page for the specified #{att}" do
        cache_expires.should be_close(@expire_mins.minutes.from_now, 30)
      end
      it "should re-cache the page if the expire_time is past" do
        if USING_RACK_CACHE
          unless `ls #{@cache_dir}/meta`.blank?
            file_name = `ls -1 #{@cache_dir}/meta/*/*`.strip
            file_contents = `cat #{file_name}`
            year = Time.now.strftime('%Y')
            file_contents = file_contents.sub(" #{year} ", " #{(year.to_i-1).to_s} ")
            FileUtils.rm(file_name)
            File.open(file_name, 'w') { |f| f.write(file_contents) }
          end
        else
          file_contents = YAML.load_file(@cache_file)
          file_contents['expires'] = 1.year.ago
          FileUtils.rm(@cache_file)
          File.open(@cache_file, 'w') { |f| f.write(file_contents.to_yaml) }
        end
        `sleep 1`
        2.times { get "#{@page.slug}" }
        page_is_cached(@page).should be_true
        response.headers['Age'].should == "0" if USING_RACK_CACHE
        cache_expires.should be_close(@expire_mins.minutes.from_now, 30)
      end
    end
  end

  after(:each) do
    @cache.clear
  end

end
