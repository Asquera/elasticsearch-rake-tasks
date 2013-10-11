require "json"
require "helpers"

BASE_PATH = "resources/elasticsearch/"
TEMPLATES_PATH = "#{BASE_PATH}templates/"
SEED_PATH = "#{BASE_PATH}dumps/"

@es_server = "http://localhost:9200/"
@es_index = "default"

def ensure_elasticsearch_configuration_present!
  raise "ES_SERVER not set!" unless @es_server
  raise "ES_INDEX not set!" unless @es_index
end

namespace :es do
  desc "Seed the elasticsearch cluster with the data dump"
  task :seed do
    ensure_elasticsearch_configuration_present!
    raise "need seed data in #{SEED_PATH}seed.json" unless File.exist?("#{SEED_PATH}seed.json")
    curl_request("POST", "#{@es_server}/#{@es_index}/_bulk", "--data-binary @#{SEED_PATH}seed.json")
  end

  desc "Dump the elasticsearch index to the seed file"
  task :dump do
    require "eson-http"
    require "eson-more"
    ensure_elasticsearch_configuration_present!

    c = Eson::HTTP::Client.new(:server => @es_server, :default_parameters => {:index => @es_index})
    # this is a workaround for a current bug that disallows passing auto_call directly to #bulk
    bulk_client = Eson::HTTP::Client.new(:auto_call => false)
    File.open("#{SEED_PATH}seed.json", "w") do |f|
      c.all(:index => @es_index) do |chunk|
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

  Dir["#{TEMPLATES_PATH}*"].each do |folder|
    name = folder.split("/").last
    namespace name do
      desc "compile the #{name} template and prints it to STDOUT"
      task :compile do
        reader = Reader.new
        puts reader.compile_template(name)
      end

      desc "resets the given index, replacing the mapping with a current one"
      task :reset do
        ensure_elasticsearch_configuration_present!
        url = "#{@es_server}/#{@es_index}"
        curl_request("DELETE", url)
        curl_request("POST", url, "-d #{compile_template(name)}")
      end
    end
  end
end

