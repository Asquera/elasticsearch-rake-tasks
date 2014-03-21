require "json"
require "elasticsearch-rake-tasks"
require "eson-http"

BASE_PATH      = "resources/elasticsearch/"
TEMPLATES_PATH = "#{BASE_PATH}templates/"
SEED_PATH      = "#{BASE_PATH}dumps/"

# set variables from environment variables if available
@es_server = ENV['ES_SERVER']
@es_index  = ENV['ES_INDEX']

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

  desc "Creates new index"
  task :create, :server, :index do |t, args|
    args.with_defaults(:server => @es_server)

    client = Eson::HTTP::Client.new(:server => args[:server]).with(:index => args[:index])
    client.create_index
  end

  desc "Dump elasticsearch index from one into another"
  task :reindex, :server, :index, :to_index do |t, args|
    args.with_defaults(:server => @es_server, :index => @es_index)

    require 'eson-more'

    client = Eson::HTTP::Client.new(:server => args[:server]).with(:index => args[:index])
    client.reindex(args[:index], args[:to_index])
  end

  desc "Deletes a given index, NOTE use this task carefully!"
  task :delete, :server, :index do |t, args|
    client = Eson::HTTP::Client.new(:server => args[:server]).with(:index => args[:index])
    client.delete_index
  end

  desc "Deletes a given template, NOTE use with care"
  task :delete_template, :server, :template do |t, args|
    client = Eson::HTTP::Client.new(:server => args[:server])
    client.delete_template(name: args[:template])
  end

  Dir["#{TEMPLATES_PATH}*"].each do |folder|
    name = folder.split("/").last
    namespace name do
      desc "Compile the #{name} template and prints it to STDOUT"
      task :compile do
        compiler = Elasticsearch::Template::Compiler.new TEMPLATES_PATH
        puts JSON.dump compiler.compile(name)
      end

      desc "Compiles and uploads the #{name} template"
      task :create, :server, :template do |t, args|
        args.with_defaults(:server => @es_server, :template => name)

        compiler = Elasticsearch::Template::Compiler.new TEMPLATES_PATH
        content  = compiler.compile(name)
        client   = Eson::HTTP::Client.new(:server => args[:server])

        client.put_template content.merge(name: args[:template])
      end

      desc "Deletes the #{name} template and recreates it"
      task :reset, :server do |t, args|
        args.with_defaults(:server => @es_server)

        compiler = Elasticsearch::Template::Compiler.new TEMPLATES_PATH
        content  = compiler.compile(name)
        client   = Eson::HTTP::Client.new(:server => args[:server])

        begin
          client.delete_template(name: name)
        rescue; end
        client.put_template content.merge(name: name)
      end

      desc "Sets an alias to a specific index"
      task :alias, :server, :index do |t, args|
        args.with_defaults(:server => @es_server)

        require "eson-more"

        client = Eson::HTTP::Client.new(:server => args[:server])
        update_alias(client, name, args[:index])
      end

      desc "Updates the index to a new version with template #{name}"
      task :flip, :server, :old_index, :new_index do |t,args|
        args.with_defaults(:server => @es_server)

        server    = args[:server]
        old_index = args[:old_index]
        new_index = args[:new_index]

        Rake::Task["es:create"].invoke(server, new_index)
        Rake::Task["es:reindex"].invoke(server, old_index, new_index)
        Rake::Task["es:#{name}:alias"].invoke(server, new_index)
      end
    end
  end
end
