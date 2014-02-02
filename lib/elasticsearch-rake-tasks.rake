require "json"
require "elasticsearch-rake-tasks"

BASE_PATH = "resources/elasticsearch/"
TEMPLATES_PATH = "#{BASE_PATH}templates/"
SEED_PATH = "#{BASE_PATH}dumps/"

# set variables from environment variables if available
@es_server = ENV['ES_SERVER']
@es_index  = ENV['ES_INDEX']

def validate_elasticsearch_configuration!(server, index)
  raise "ES_SERVER not set!" unless server
  raise "ES_INDEX not set!" unless index
end

namespace :es do
  desc "Seed the elasticsearch cluster with the data dump"
  task :seed, :server, :index do |t, args|
    args.with_defaults(:server => @es_server, :index => @es_index)

    server = args[:server]
    index = args[:index]

    validate_elasticsearch_configuration!(server, index)

    raise "need seed data in #{SEED_PATH}seed.json" unless File.exist?("#{SEED_PATH}seed.json")
    sender = Elasticsearch::Helpers::ChunkedSender.new("#{server}/#{index}/_bulk")
    File.open("#{SEED_PATH}seed.json", "rb") do |io|
      sender.send io
    end
  end

  desc "Dump the elasticsearch index to the seed file"
  task :dump, :server, :index do |t, args|
    args.with_defaults(:server => @es_server, :index => @es_index)

    require "eson-http"
    require "eson-more"

    server = args[:server]
    index = args[:index]

    validate_elasticsearch_configuration!(server, index)

    FileUtils.mkdir_p(SEED_PATH)

    c = Eson::HTTP::Client.new(:server => server, :default_parameters => {:index => index})
    # this is a workaround for a current bug that disallows passing auto_call directly to #bulk
    bulk_client = Eson::HTTP::Client.new(:auto_call => false)
    File.open("#{SEED_PATH}seed.json", "w") do |f|
      c.all(:index => index) do |chunk|
        if chunk.size > 0
          b = bulk_client.bulk do |b|
            chunk.each do |doc|
              b.index :index => nil,
                      :type => doc["_type"],
                      :id => doc["_id"],
                      :doc => doc["_source"]
            end
          end
          f << b.source
        end
      end
    end
  end

  desc "Dump elasticsearch index from one into another"
  task :reindex, :server, :index, :to_index do |t, args|
    args.with_defaults(:server => @es_server, :index => @es_index)

    require "eson-http"
    require "eson-more"
    server = args[:server]
    index  = args[:index]
    to_index = args[:to_index]

    validate_elasticsearch_configuration!(server, index)

    client = Eson::HTTP::Client.new(:server => server, :default_parameters => {:index => index})
    client.reindex(index, to_index)
  end

  Dir["#{TEMPLATES_PATH}*"].each do |folder|
    name = folder.split("/").last
    namespace name do
      desc "Compile the #{name} template and prints it to STDOUT"
      task :compile do
        reader = Elasticsearch::Helpers::Reader.new TEMPLATES_PATH
        puts reader.compile_template(name)
      end

      desc "Deletes the #{name} template and recreates it"
      task :reset, :server do |t, args|
        args.with_defaults(:server => @es_server)

        server = args[:server]

        ensure_elasticsearch_configuration_present!(server, true)
        reader = Elasticsearch::Helpers::Reader.new TEMPLATES_PATH

        url = "#{server}/_template/#{name}"
        Elasticsearch::Helpers.curl_request("DELETE", url)
        Elasticsearch::Helpers.curl_request("PUT", url, "-d #{Shellwords.escape(reader.compile_template(name))}")
      end
    end
  end
end

