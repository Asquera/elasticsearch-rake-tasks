require "json"
require "elasticsearch-rake-tasks"
require "eson-http"

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

def update_alias(client, name, new_index)
  indices = client.get_aliases.select{ |k,v| v['aliases'] && v['aliases'][name] }
  client.aliases do |req|
    indices.each{ |k,v| req.remove k, name }
    req.add new_index, name
  end
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

    require 'eson-more'

    client = Eson::HTTP::Client.new(:server => args[:server]).with(:index => args[:index])
    client.reindex(args[:index], args[:to_index])
  end

  Dir["#{TEMPLATES_PATH}*"].each do |folder|
    name = folder.split("/").last
    namespace name do
      desc "Compile the #{name} template and prints it to STDOUT"
      task :compile do
        reader = Elasticsearch::Helpers::Reader.new TEMPLATES_PATH
        puts reader.compile_template_to_string(name)
      end

      desc "Deletes the #{name} template and recreates it"
      task :reset, :server do |t, args|
        args.with_defaults(:server => @es_server)

        reader  = Elasticsearch::Helpers::Reader.new TEMPLATES_PATH
        content = reader.compile_template(name)
        client  = Eson::HTTP::Client.new(:server => args[:server])

        begin
          client.delete_template(name: name)
        rescue; end
        client.put_template content.merge(name: name)
      end

      desc "Creates new index with the template #{name}"
      task :create, :server, :index do |t, args|
        args.with_defaults(:server => @es_server)

        reader  = Elasticsearch::Helpers::Reader.new TEMPLATES_PATH
        content = reader.compile_template(name)
        client  = Eson::HTTP::Client.new(:server => args[:server]).with(:index => args[:index])

        client.put_template content.merge(name: name)
        begin
          client.create_index
        rescue; end
      end

      desc "Sets an alias to a specific index"
      task :alias, :server, :index do |t, args|
        args.with_defaults(:server => @es_server)

        require "eson-http"
        require "eson-more"
        server = args[:server]
        index  = args[:index]

        validate_elasticsearch_configuration!(server, index)

        client = Eson::HTTP::Client.new(:server => server)
        update_alias(client, name, index)
      end

      desc "Updates the index to a new version with template #{name}"
      task :flip, :server, :old_index, :new_index do |t,args|
        args.with_defaults(:server => @es_server)

        server    = args[:server]
        old_index = args[:old_index]
        new_index = args[:new_index]

        Rake::Task["es:#{name}:create"].invoke(server, new_index)
        Rake::Task["es:reindex"].invoke(server, old_index, new_index)
        Rake::Task["es:#{name}:alias"].invoke(server, new_index)
      end
    end
  end
end
