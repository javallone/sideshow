module Mplayer
    class Control
        attr_accessor :command
        attr_accessor :env

        def initialize(command, display = ":0")
            self.command = command
            self.env = { "DISPLAY" => display }
            @open = false
        end

        def open(file)
            self.stop if @open

            @stdout, w = IO.pipe
            r, @stdin = IO.pipe
            @process = Process.spawn(self.env, self.command.sub("%DVD_IMAGE%", file),
                :out => w,
                :in => r,
                :err => "/dev/null")
            nil
            Process.detach(@process)
            @open = true
        end

        def send_command(cmd)
            if @open
                begin
                    while true
                        @stdout.read_nonblock(1000)
                    end
                rescue Errno::EAGAIN
                    # Do nothing
                end
                @stdin.puts(cmd)
                sleep(0.25)

                result = ''
                begin
                    while true
                        result += @stdout.read_nonblock(1000)
                    end
                rescue
                    # Do nothing
                end

                result.sub(/\n$/, "")
            end
        end

        def get_property(name)
            result = self.send_command("pausing_keep_force get_property #{name}")

            if result.match("ANS_#{name}=")
                property = Property.new(name)
                property.mplayer_value = result.sub("ANS_#{name}=", "")
                return property.to_object
            else
                return result # TODO: Throw an exception
            end
        end

        def set_property(name, value)
            property = Property.new(name)
            property.value = value;

            if property.set?
                self.send_command("pausing_keep_force set_property #{name} #{property.mplayer_value}")
            end
        end

        def step_property(name, value = 0, direction = 1)
            property = Property.new(name)

            if property.step?
                self.send_command("pausing_keep_force step_property #{name} #{value} #{direction}")
            end
        end

        def nav(button)
            self.send_command("dvdnav #{button.to_s}")

            case button
            when :select
                self.set_property(:sub_forced_only, true)
            when :menu
                self.set_property(:sub_forced_only, false)
            end
        end

        def pause
            self.send_command("pause")
        end

        def paused?
            self.get_property(:pause)
        end

        def stop
            self.send_command("stop")
            @open = false
        end

        def chapter
            self.get_property(:chapter)
        end

        def chapter=(chapter)
            self.set_property(:chapter, chapter)
        end

        def chapters
            self.get_property(:chapters)
        end

        def pos
            self.get_property(:time_pos)
        end

        def pos=(pos)
            self.set_property(:stream_time_pos, pos) # Returns a more accurate value, but can't be set
        end

        def length
            self.get_property(:length)
        end

        def seek(value, method = :relative)
            case method
            when :relative
                type = 0
            when :percent
                type = 1
            when :absolute
                type = 2
            end
            self.send_command("seek #{value} #{type}")
        end

        def seek_chapter(direction)
            self.step_property(:chapter, 1, direction)
        end
    end
end
