module Sideshow
    module Model
        class Setting
            include DataMapper::Resource

            storage_names[:default] = "settings"

            property :name, String, :unique => true, :key => true
            property :value, String, :length => 255

            def self.getAll()
                result = {}
                Setting.all.each do |s|
                    result[s.name.to_sym] = s.value
                end

                result
            end

            def self.get(name)
                s = Setting.first(:name => name.to_s)
                s.value unless s.nil?
            end

            def self.set(name, value)
                s = Setting.first_or_create(:name => name.to_s)
                s.value = value
                s.save
            end
        end
    end
end
