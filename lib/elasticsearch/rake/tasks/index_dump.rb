require "eson-http"
require "eson-more"

module Elasticsearch
  module Rake
    module Tasks
      class IndexDump
        attr_reader :server, :index
        attr_reader :client

        def initialize(args = {})
          @server = args.fetch(:server){ raise "No es server given" }
          @index  = args.fetch(:index){ raise "No es index given" }
          @client = Eson::HTTP::Client.new(:server => server).with(:index => index)
        end

        def to_file(seed_file)
          bulk_client = Eson::HTTP::Client.new(:auto_call => false)
          File.open(seed_file, 'w') do |file|
            client.all(:index => index) do |chunk|
              unless chunk.empty?
                bulk = index_chunk(bulk_client, chunk)
                file << bulk.source
              end
            end
          end
        end

        def index_chunk(client, chunks)
          client.bulk do |b|
            chunks.each do |doc|
              b.index :index => nil,
                      :type  => doc["_type"],
                      :id    => doc["_id"],
                      :doc   => doc["_source"]
            end
          end
        end
      end
    end
  end
end
