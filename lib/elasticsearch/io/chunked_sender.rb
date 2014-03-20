module Elasticsearch
  module IO
    class ChunkedSender
      attr_reader :sink

      def initialize(sink)
        @sink = sink
      end

      def send(io)
        counter = 0
        buffer  = ''
        io.each_line do |line|
          counter += 1
          buffer << line
          if 0 == (counter % 2)
            sink << buffer
            buffer = ''
          end
        end
        sink.flush
      end
    end
  end
end
