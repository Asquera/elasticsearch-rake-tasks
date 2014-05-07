require "json"
require "elasticsearch-rake-tasks"
require "eson-http"

# to set a custom logger
# Elasticsearch::Logging.logger = MyLogger.new

BASE_PATH      = "resources/elasticsearch/" unless defined?(BASE_PATH)
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

def log_info(line)
  Elasticsearch::Logging.logger.info line
end

def esclient_with_template(template, server, &block)
  compiler = Elasticsearch::Template::Compiler.new TEMPLATES_PATH
  content  = compiler.compile(template)
  client   = Eson::HTTP::Client.new(:server => server)

  if block_given?
    block.call(client, content)
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
    log_info "Uploading '#{SEED_PATH}seed.json' to '#{args[:server]}/#{args[:index]}'"
    seeder.upload("#{SEED_PATH}seed.json")
  end

  desc "Dump the elasticsearch index to the seed file"
  task :dump, :server, :index do |t, args|
    args.with_defaults(:server => @es_server, :index => @es_index)

    index_dump = Elasticsearch::Rake::Tasks::IndexDump.new(
      :server => args[:server],
      :index  => args[:index],
    )
    log_info "Dumping docs from '#{args[:server]}/#{args[:index]}' to '#{SEED_PATH}seed.json'"
    index_dump.to_file("#{SEED_PATH}seed.json")
  end

  desc "Creates new index"
  task :create, :server, :index do |t, args|
    args.with_defaults(:server => @es_server)

    client = Eson::HTTP::Client.new(:server => args[:server]).with(:index => args[:index])
    log_info "Creating index '#{args[:server]}/#{args[:index]}'"
    client.create_index
  end

  desc "Dump elasticsearch index from one into another"
  task :reindex, :server, :index, :to_index do |t, args|
    args.with_defaults(:server => @es_server, :index => @es_index)

    require 'eson-more'

    client = Eson::HTTP::Client.new(:server => args[:server]).with(:index => args[:index])
    log_info "Reindexing '#{args[:server]}/#{args[:index]}' to index '#{args[:to_index]}'"
    client.reindex(args[:index], args[:to_index])
  end

  desc "Deletes a given index, NOTE use this task carefully!"
  task :delete, :server, :index do |t, args|
    client = Eson::HTTP::Client.new(:server => args[:server]).with(:index => args[:index])
    log_info "Deleting index '#{args[:server]}/#{args[:index]}'"
    client.delete_index
  end

  desc "Deletes a given template, NOTE use with care"
  task :delete_template, :server, :template do |t, args|
    client = Eson::HTTP::Client.new(:server => args[:server])
    log_info "Deleting template '#{args[:template]}' at '#{args[:server]}'"
    client.delete_template :name => args[:template]
  end

  Dir["#{TEMPLATES_PATH}*"].each do |folder|
    name = folder.split("/").last
    namespace name do
      desc "Compile the #{name} template and prints it to STDOUT"
      task :compile do
        compiler = Elasticsearch::Template::Compiler.new TEMPLATES_PATH
        log_info "Compiling template '#{name}'"
        puts JSON.dump compiler.compile(name)
      end

      desc "Compiles and uploads the #{name} template"
      task :upload, :server, :template do |t, args|
        args.with_defaults(:server => @es_server, :template => name)

        esclient_with_template(name, args[:server]) do |client, content|
          log_info "Uploading template '#{name}' as '#{args[:template]}' to '#{args[:server]}'"
          client.put_template content.merge(name: args[:template])
        end
      end

      desc "Creates an index with the #{name} template"
      task :create, :server, :index do |t, args|
        args.with_defaults(:server => @es_server)

        esclient_with_template(name, args[:server]) do |client, content|
          content.delete('template')
          log_info "Creating index #{args[:index]} with template '#{name}' at '#{args[:server]}'"
          client.create_index content.merge(index: args[:index])
        end
      end

      desc "Deletes the #{name} template and recreates it"
      task :reset, :server, :template do |t, args|
        args.with_defaults(:server => @es_server, :template => name)

        esclient_with_template(name, args[:server]) do |client, content|
          log_info "Resetting template '#{name}' as '#{args[:template]}' to '#{args[:server]}'"
          client.delete_template(name: args[:template])
          client.put_template content.merge(name: args[:template])
        end
      end

      desc "Sets an alias to a specific index"
      task :alias, :server, :index, :alias do |t, args|
        args.with_defaults(:server => @es_server, :alias => name)

        require "eson-more"

        client = Eson::HTTP::Client.new(:server => args[:server])
        log_info "Setting alias '#{name}' to index '#{args[:index]}' at '#{args[:server]}'"
        update_alias(client, args[:alias], args[:index])
      end

      desc "Updates the index to a new version with template #{name}"
      task :flip, :server, :old_index, :new_index do |t,args|
        args.with_defaults(:server => @es_server)

        server    = args[:server]
        old_index = args[:old_index]
        new_index = args[:new_index]

        log_info "Flip index from '#{args[:old_index]}' to '#{args[:new_index]}' at '#{args[:server]}'"
        Rake::Task["es:create"].invoke(server, new_index)
        Rake::Task["es:reindex"].invoke(server, old_index, new_index)
        Rake::Task["es:#{name}:alias"].invoke(server, new_index)
      end
    end
  end
end
