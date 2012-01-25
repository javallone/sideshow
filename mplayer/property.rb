module Mplayer
    class Property
        def self.properties
            {
                :pause =>           { :type => :flag,  :set => false, :step => false },
                :chapter =>         { :type => :int,   :set => true,  :step => true },
                :chapters =>        { :type => :int,   :set => false, :step => false },
                :length =>          { :type => :time,  :set => false, :step => false },
                :percent_pos =>     { :type => :int,   :set => true,  :step => true },
                :time_pos =>        { :type => :time,  :set => true,  :step => true },
                :stream_time_pos => { :type => :time,  :set => false, :step => false },
                :sub_forced_only => { :type => :flag,  :set => true,  :step => true }
            }
        end

        attr_accessor :name
        attr_accessor :value
        attr_accessor :mplayer_value

        def initialize(name)
            self.name = name
            self.value = value
        end

        def name=(name)
            @name = name.to_sym
        end

        def value
            case Property.properties[self.name][:type]
            when :int
                return @value.to_i
            when :float
                return @value.to_f
            when :flag
                return (@value == "1")
            when :time
                return @value.to_i
            else
                return @value
            end
        end

        def value=(value)
            case Property.properties[self.name][:type]
            when :flag
                @value = (value ? "1" : "0");
            else
                @value = value.to_s
            end
        end

        def mplayer_value
            @value
        end

        def mplayer_value=(value)
            case Property.properties[self.name][:type]
            when :flag
                @value = (value == "yes" ? "1" : "0")
            else
                @value = value
            end
        end

        def set?
            Property.properties[self.name][:set]
        end

        def step?
            Property.properties[self.name][:step]
        end

        def to_object
            self.value
        end

        def to_mplayer
            self.mplayer_value
        end
    end
end
