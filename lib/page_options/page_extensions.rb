module PageOptions::PageExtensions
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
      def cache_setting
        @page = Page.find(self.id)
        case true
        when @page.cache_expire_minutes == 0 && @page.cache_expire_time == nil: "Default"
        when @page.cache_expire_minutes == -1: "No Caching"
        when @page.cache_expire_minutes == 1: "1 minute"
        when @page.cache_expire_minutes > 1: "#{@page.cache_expire_minutes} minutes"
        when @page.cache_expire_time != nil && @page.cache_expire_time.is_a?(Time)
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
      seconds = ResponseCache.defaults[:expire_time]
      cache_expire_time = case true
        when seconds >= 86400
          "#{seconds/86400} days"
        when seconds >= 3600
          "#{seconds/3600} hours"
        when seconds >= 120
          "#{seconds/60} minutes"
        else
          "#{seconds} seconds"
      end
      cache_expire_time = cache_expire_time.chop if cache_expire_time[0,1] == "1"
      cache_expire_time
    end
  end

end
