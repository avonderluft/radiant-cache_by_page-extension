module CacheByPage::PageExtensions
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      validates_numericality_of :cache_expire_minutes, :allow_nil => false, :only_integer => true,
                                :message => 'must be a whole number'
      def validate
        self.cache_expire_minutes = -1 if self.cache_expire_minutes.to_i < -1
        if self.cache_expire_minutes.to_i != 0 && self.changes.include?("cache_expire_minutes")
          self.cache_expire_time = nil
        end
        if self.cache_expire_time != nil && self.changes.include?("cache_expire_time")
          self.cache_expire_minutes = 0
        end
        super
      end

      def cache?
        self.cache_expire_minutes.to_i >= 0
      end
      def cache_override?
        self.cache_expire_minutes.to_i > 0 || self.cache_expire_time != nil
      end
      def cache_duration
        @page = Page.find(self.id)
        case true
        when @page.cache_expire_minutes == 0 && @page.cache_expire_time == nil
          if SiteController.respond_to?('cache_timeout')
            SiteController.cache_timeout
          else
            ResponseCache.defaults[:expire_time]
          end
        when @page.cache_expire_minutes == -1 then nil
        when @page.cache_expire_minutes >= 1 then @page.cache_expire_minutes.minutes
        when @page.cache_expire_time != nil && @page.cache_expire_time.is_a?(Time) then
          next_expire_time = @page.cache_expire_time < Time.now ? @page.cache_expire_time.tomorrow : @page.cache_expire_time
          (next_expire_time - Time.now).round
        else nil
        end
      end
      def cache_setting
        @page = Page.find(self.id)
        case true
        when @page.cache_expire_minutes == 0 && @page.cache_expire_time == nil then Page.default_caching
        when @page.cache_expire_minutes == -1 then "No Caching"
        when @page.cache_expire_minutes == 1 then "1 minute"
        when @page.cache_expire_minutes > 1 then "#{@page.cache_expire_minutes} minutes"
        when @page.cache_expire_time != nil && @page.cache_expire_time.is_a?(Time) then
          "Daily at #{@page.cache_expire_time.strftime("%H")}:#{@page.cache_expire_time.strftime("%M")}"
        else "Not set"
        end
      end
      alias_method_chain :process, :expire_time
    end
  end

  def process_with_expire_time(request, response)
    if cache?
      if cache_expire_minutes.to_i > 0
        response.cache_timeout = cache_expire_minutes.minutes.from_now
      elsif ! cache_expire_time.nil?
        expire_time = Time.parse("#{cache_expire_time.hour}:#{cache_expire_time.min}")
        response.cache_timeout = expire_time < Time.now ? expire_time.tomorrow : expire_time
      end
    end
    process_without_expire_time(request, response)
  end

  module ClassMethods
    def default_caching
      seconds = SiteController.respond_to?('cache_timeout') ? SiteController.cache_timeout : ResponseCache.defaults[:expire_time] 
      cache_expire_time = case true
        when seconds >= 86400 then "#{seconds/86400} days"
        when seconds >= 3600 then "#{seconds/3600} hours"
        when seconds >= 120 then "#{seconds/60} minutes"
        else "#{seconds} seconds"
      end
      cache_expire_time = cache_expire_time.chop if cache_expire_time[0,1] == "1"
      cache_expire_time
    end
  end

end
