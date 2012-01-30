require "eventmachine"

require_relative "controller"

module Sideshow
    module NetworkController
        def self.init(host, port)
            Thread.new do
                EventMachine::run do
                    EventMachine.start_server host, port, Sideshow::NetworkController
                end
            end
        end

        def post_init
            puts("Console connection...")
        end

        def receive_data data
            cleaned = data.sub("\n", "").sub("\x0d", "")

            case cleaned
                when "status"
                    status = Controller.mplayer.nil? ? 'stopped' : 'playing'
                    send_data(">>> #{status}\n")
                else
                    begin
                        result = Controller.mplayer.send_command(cleaned)
                        send_data(">>> #{result}\n")
                    rescue
                        send_data(">>> (command '#{cleaned}' failed)\n")
                    end
            end
        end
    end
end
