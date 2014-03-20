require 'faraday'

module Elasticsearch
  module IO
    class BulkSink
      MAX_BYTES = 1024 * 1024 * 10 # 10 Mb

      attr_reader :target_url, :max_bytes
      attr_reader :connection
      attr_reader :buffer

      def initialize(target_url, opts = {})
        @target_url = target_url
        @max_bytes  = opts.fetch(:max_bytes, MAX_BYTES)
        @buffer     = ''
      end

      def <<(line)
        buffer << line
        if buffer.bytesize >= max_bytes
          flush
        end
      end

      def flush
        connection.post '', buffer
        buffer.clear
      end

      def connection
        @connection ||= Faraday.new(:url => target_url) do |conn|
          conn.adapter Faraday.default_adapter
        end
        @connection
      end
    end
  end
end
