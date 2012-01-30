require File.join(File.dirname(__FILE__), 'sideshow/sideshow')

Sideshow::Model.init(ENV['DB'])
Sideshow::App.init()

unless ENV['REMOTE_CONTROL_PORT'].nil? or ENV['REMOTE_CONTROL_HOST'].nil?
    Sideshow::NetworkController.init(ENV['REMOTE_CONTROL_HOST'], ENV['REMOTE_CONTROL_PORT'])
end

map "/static" do
    run Rack::File.new(File.join(File.dirname(__FILE__), 'static'))
end

map "/control" do
    run Sideshow::Controller
end

map "/" do
    run Sideshow::App
end
