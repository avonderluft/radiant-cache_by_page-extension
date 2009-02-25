module PageOptions::PageExtensions
  def self.included(base)
    base.class_eval do
      def validate
        self.cache_expire_minutes = 0 if ! self.cache_expire_minutes.is_a?(Integer)
        self.cache_expire_minutes = -1 if self.cache_expire_minutes.to_i < -1
        if self.cache_expire_minutes.to_i != 0 && self.changes.include?("cache_expire_minutes")
          self.cache_expire_time = nil
        end
        if self.cache_expire_time != nil && self.changes.include?("cache_expire_time")
          self.cache_expire_minutes = 0
        end
        super
        unless self.cache_expire_time.blank? 
          errors.add("cache_expire_time", "the expiration hour must be set")  if self.cache_expire_time.hour.blank?
          errors.add("cache_expire_time", "the expiration minute must be set") if self.cache_expire_time.min.blank?
        end
      end   
      def cache?
        ! self.cache_expire_minutes.to_i == -1
      end
      alias_method_chain :process, :expire_time
    end
  end 
  
  def process_with_expire_time(request, response)
    if cache?
      if cache_expire_minutes.to_i > 0
        response.cache_timeout = cache_expire_minutes.minutes.from_now
      elsif ! cache_expire_time.nil?
        time = cache_expire_time
        exp = time < Time.now ? 1.day.from_now : Time.now
        response.cache_timeout = Time.parse("#{exp.year}-#{exp.month}-#{exp.day}-#{time.hour}:#{time.min}")
      end
    end
    process_without_expire_time(request, response)
  end
end