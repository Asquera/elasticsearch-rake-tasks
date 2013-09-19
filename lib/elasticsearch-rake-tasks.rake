require "json"

def ensure_elasticsearch_configuration_present!
  raise "ES_SERVER not set!" unless @es_server
  raise "ES_INDEX not set!" unless @es_index
end

def read_and_parse_json_file(file)
  JSON.parse File.read file
rescue Exception => e
  puts "error while reading file #{file}"
  raise e
end

def read_and_parse_yaml_file(file)
  YAML.load File.read file
rescue Exception => e
  puts "error while reading file #{file}"
  raise e
end

def read_and_parse_file(file)
  case File.extname(file)
  when ".json"
    read_and_parse_json_file(file)
  when ".yaml", ".yml"
    read_and_parse_yaml_file(file)
  end
end


def read_settings(mapping)
  filename = "resources/elasticsearch-templates/#{mapping}/settings.yaml"
  if File.exist?(filename)
    read_and_parse_file(filename)
  else
    {}
  end
end

def read_mappings(mapping)
  mappings = {}

  Dir.chdir("resources/elasticsearch-templates/#{mapping}/mappings/") do
    paths = Dir['*.{json,yml,yaml}']
    if default_file = paths.find { |f| f =~ /_default\.*/ }
      default = read_and_parse_file default_file
      paths.delete default_file
    end
    
    paths.each do |p|
      name, _ = p.split(".")
      content = read_and_parse_file p
      mappings[name] = default.deep_merge(content)
    end
  end

  mappings
end

# reads the template pattern from the file
# see http://www.elasticsearch.org/guide/reference/api/admin-indices-templates/
# for usage and format of the template pattern
def read_template_pattern(mapping)
  filename = "resources/elasticsearch-templates/#{mapping}/template_pattern"
  if File.exist?(filename)
    File.read(filename).chomp
  else
    nil
  end
end

def compile_template(name)
  require 'active_support/core_ext/hash/deep_merge'
  mappings = read_mappings(name)
  settings = read_settings(name)
  template_pattern = read_template_pattern(name)
  output = { "settings" => settings, "mappings" => mappings }
  output['template'] = template_pattern if template_pattern
  JSON.dump output
end

namespace :es do
  desc "Seed the elasticsearch cluster with the data dump"
  task :seed do
    ensure_elasticsearch_configuration_present!
    raise "need seed data in resources/dumps/elasticsearch.json" unless File.exist?("resources/dumps/elasticsearch.json")
    `curl -XPOST #{@es_server}/#{@es_index}/_bulk --data-binary @resources/dumps/elasticsearch.json`
  end

  desc "Dump the elasticsearch index to the seed file"
  task :dump do
    require 'eson-http'
    require 'eson-more'
    ensure_elasticsearch_configuration_present!

    c = Eson::HTTP::Client.new(:server => @es_server, :default_parameters => {:index => @es_index})
    # this is a workaround for a current bug that disallows passing auto_call directly to #bulk
    bulk_client = Eson::HTTP::Client.new(:auto_call => false)
    File.open('resources/dumps/elasticsearch.json', "w") do |f|
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

  Dir["resources/elasticsearch-templates/*"].each do |folder|
    name = folder.split("/").last
    namespace name do
      desc "compile the #{name} template and prints it to STDOUT"
      task :compile do
        puts compile_template(name)
      end

      desc "resets the given index, replacing the mapping with a current one"
      task :reset do
        ensure_elasticsearch_configuration_present!
        `curl -XDELETE #{@es_server}/#{@es_index}`
        `curl -XPOST #{@es_server}/#{@es_index} -d '#{compile_template(name)}'`
      end
    end
  end
end

