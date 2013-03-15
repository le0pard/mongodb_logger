# https://github.com/bitboxer/simple_progressbar
module MongodbLogger
  module Utils
    class Progressbar
      def initialize
        @last_length = 0
        @title = ""
        @progress = 0
      end

      def show(title, &block)
        @title = title
        print @title + " "
        start_progress
        # thanks to http://www.dcmanges.com/blog/ruby-dsls-instance-eval-with-delegation
        @self_before_instance_eval = eval "self", block.binding
        instance_eval(&block)
        finish_progress
      end

      def interrupt
        # TODO: Make some of the strings constants so we don't have to use a magic number here.
        progressbar_length = 16 + @last_length + @title.length
        move_cursor = "\e[#{progressbar_length}D"
        print move_cursor + (" " * progressbar_length) + move_cursor
        STDOUT.flush
        yield
        puts
        print @title + " "
        render_progress(@progress)
      end

      def progress(percent)
        print "\e[#{15 + @last_length}D"
        render_progress(percent)
      end

      def method_missing(method, *args, &block)
        @self_before_instance_eval.send method, *args, &block
      end

      private

      def render_progress(percent)
        @progress = percent
        print "["

        print "*" * [(percent/10).to_i, 10].min
        print " " * [10 - (percent/10).to_i, 0].max

        if percent.class != Float
          printable_percent = "%3s" % percent
        else
          non_decimal_digits = (Math.log(percent) / Math.log(10)).truncate + 1
          printable_percent = (non_decimal_digits < 3 ? " " * (3 - non_decimal_digits) : "") + percent.to_s
        end

        print "]\e[32m #{printable_percent}\e[0m %"

        new_length = printable_percent.length
        if @last_length > new_length
          print " " * (@last_length - new_length)
          print "\e[#{@last_length - new_length}D"
        end
        @last_length = new_length

        STDOUT.flush
      end

      def start_progress
        render_progress(0)
      end

      def finish_progress
        puts
      end
    end
  end
end