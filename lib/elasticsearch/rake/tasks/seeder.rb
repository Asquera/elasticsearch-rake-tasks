module Elasticsearch
  module Rake
    module Tasks
      class Seeder
        attr_reader :server, :index
        attr_reader :sender

        def initialize(args = {})
          opts = args.reject{ |k,v| v.nil? }
          @server = opts.fetch(:server){ raise "No es server given" }
          @index  = opts.fetch(:index){ raise "No es index given" }
          @sender = Elasticsearch::IO::ChunkedSender.new(sink)
        end

        def sink
          @sink ||= Elasticsearch::IO::BulkSink.new("#{server}/#{index}/_bulk")
        end

        def upload(seed_file)
          raise "Need seed file in #{seed_file}" unless File.exist?(seed_file)
          File.open(seed_file, 'rb') do |io|
            sender.send io
          end
        end
      end
    end
  end
end
