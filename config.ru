require File.join(File.dirname(__FILE__), 'sideshow/sideshow')

Sideshow::Model.init(ENV['DB'])
Sideshow::App.init()

map "/static" do
    run Rack::File.new(File.join(File.dirname(__FILE__), 'static'))
end

map "/control" do
    run Sideshow::Controller
end

map "/" do
    run Sideshow::App
end
