require "json"
require "elasticsearch-rake-tasks"

BASE_PATH      = "resources/elasticsearch/"
TEMPLATES_PATH = "#{BASE_PATH}templates/"
SEED_PATH      = "#{BASE_PATH}dumps/"

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

    FileUtils.mkdir_p(SEED_PATH)

    seeder = Elasticsearch::Rake::Tasks::Seeder.new(
      :server => args[:server],
      :index  => args[:index]
    )
    seeder.upload("#{SEED_PATH}seed.json")
  end

  desc "Dump the elasticsearch index to the seed file"
  task :dump, :server, :index do |t, args|
    args.with_defaults(:server => @es_server, :index => @es_index)

    index_dump = Elasticsearch::Rake::Tasks::IndexDump.new(
      :server => args[:server],
      :index  => args[:index],
    )
    index_dump.to_file("#{SEED_PATH}seed.json")
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

  desc "Deletes a given index, NOTE use this task carefully!"
  task :delete, :server, :index do |t, args|
    server = args[:server]
    index  = args[:index]

    validate_elasticsearch_configuration!(server, index)

    url = "#{server}/#{index}"
    Elasticsearch::Helpers.curl_request('DELETE', url)
  end

  desc "Deletes a given template, NOTE use with care"
  task :delete_template, :server, :template do |t, args|
    server   = args[:server]
    template = args[:template]

    validate_elasticsearch_configuration!(server, true)

    url = "#{server}/_template/#{template}"
    Elasticsearch::Helpers.curl_request("DELETE", url)
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

        validate_elasticsearch_configuration!(server, true)
        reader = Elasticsearch::Helpers::Reader.new TEMPLATES_PATH

        url = "#{server}/_template/#{name}"
        Elasticsearch::Helpers.curl_request("DELETE", url)
        Elasticsearch::Helpers.curl_request("PUT", url, "-d #{Shellwords.escape(reader.compile_template(name))}")
      end

      desc "Creates new index with the template #{name}"
      task :create, :server, :index do |t, args|
        args.with_defaults(:server => @es_server)

        server = args[:server]
        index  = args[:index]

        validate_elasticsearch_configuration!(server, index)
        reader = Elasticsearch::Helpers::Reader.new TEMPLATES_PATH

        url = "#{server}/_template/#{index}/"
        Elasticsearch::Helpers.curl_request("PUT", url, "-d #{Shellwords.escape(reader.compile_template(name))}")
        url = "#{server}/#{index}/"
        Elasticsearch::Helpers.curl_request("PUT", url)
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
