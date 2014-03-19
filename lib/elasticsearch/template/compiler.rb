require 'yaml'

module Elasticsearch
  module Template
    class Compiler
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def compile(template)
        unless File.directory?("#{path}/#{template}")
          raise "Template #{template} not a directory"
        end
        mappings = read_mappings(template)
      end

      def read_mappings(template)
        mappings = {}
        Dir.chdir("#{path}/#{template}/mappings/") do
          paths = Dir['*.{yml,yaml}']

          visible_types(paths).each do |path|
            name, _ = path.split(".")
            content = parse_yaml_file(path)
            mappings[name] = content
          end
        end
        mappings
      rescue
        {}
      end

      def parse_yaml_file(file)
        YAML.load(File.read(file))
      rescue StandardError => e
        STDOUT.puts "Error while reading file #{file}: #{e}"
        raise e
      end

      def visible_types(paths)
        paths.reject{ |path| File.basename(path).start_with?("_") }
      end
    end
  end
end
