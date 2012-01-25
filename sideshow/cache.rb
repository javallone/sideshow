require 'redis'

module Sideshow
    class Cache
        def self.setup(address, prefix)
            @prefix = prefix
            @cache = nil

            unless address.nil? or address.empty?
                host, port = address.split(':')
                @cache = Redis.new(:host => host, :port => port)
            end
        end

        def self.enabled?
            not @cache.nil?
        end

        def self.get(key, timeout=0)
            key = "#{@prefix}:#{key}"
            if self.enabled?
                value = @cache.get(key)
                if value.nil?
                    value = yield
                    @cache.set(key, Marshal::dump(value))

                    timeout = Random.rand(timeout) if timeout.is_a? Range
                    @cache.expire(key, timeout) unless timeout == 0
                else
                    value = Marshal::load(value)
                end

                return value
            else
                yield
            end
        end

        def self.evict(key)
            if self.enabled?
                key = "#{@prefix}:#{key}"
                @cache.del(key)
            end
        end

        def self.flush
            if self.enabled?
                keys = @cache.keys("#{@prefix}:*")
                @cache.del(*keys)
            end
        end
    end
end
