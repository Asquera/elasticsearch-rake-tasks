require 'active_support/core_ext/hash/deep_merge'

module Elasticsearch
  module Template
    class MappingsReader
      attr_reader :path

      def initialize(template_path)
        @path = template_path
      end

      def read
        mappings = {}
        Dir.chdir("#{path}/mappings") do
          visible_types.each do |path|
            name, _ = path.split(".")
            content = parse_yaml_file(path)
            mappings[name] = content
          end
        end
        mappings
      rescue
        {}
      end

      def visible_types
        paths = Dir['*.{yml,yaml}']
        paths.reject{ |p| File.basename(p).start_with?("_") }
      end

      def parse_yaml_file(file)
        content = YAML.load(File.read(file))
        Array(content.delete('include')).each do |file|
          content = parse_yaml_file(file).deep_merge(content)
        end
        content
      rescue StandardError => e
        STDOUT.puts "Error while reading file #{file}: #{e}"
        raise e
      end
    end
  end
end
