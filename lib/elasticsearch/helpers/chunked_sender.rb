require "faraday"

module Elasticsearch
  module Helpers
    class ChunkedSender

      attr_accessor :target_url, :opts
      
      @conn = nil

      def initialize(target_url, opts = {})
        default_opts = {:max_bytes => 1024 * 1024 * 10} # 10MB
        self.target_url = target_url
        self.opts = default_opts.merge(opts)
      end

      def send(io)
        send_buffer = ''
        buffer = ''
        counter = 0
        io.each_line do |line|
          counter += 1 
          buffer << line
          if 0 == (counter % 2)
            if (send_buffer.bytesize + buffer.bytesize) < opts[:max_bytes]
              send_buffer << buffer
            else
              send_bytes(send_buffer)
              send_buffer = buffer
            end
            buffer = ''
          end
        end
        send_bytes(send_buffer)
      end

      def send_bytes(buffer)
        connection.post '', buffer      
      end

      def connection
        @conn ||= Faraday.new(:url => target_url) do |faraday|
          faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        end
        @conn
      end

    end

  end
end
