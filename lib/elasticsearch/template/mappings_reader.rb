module Elasticsearch
  module Template
    class MappingsReader
      attr_reader :path

      def initialize(mappings_path)
        @path = mappings_path
      end

      def read
        mappings = {}
        Dir.chdir(path) do
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
        paths.reject{ |path| File.basename(path).start_with?("_") }
      end

      def parse_yaml_file(file)
        YAML.load(File.read(file))
      rescue StandardError => e
        STDOUT.puts "Error while reading file #{file}: #{e}"
        raise e
      end
    end
  end
end
