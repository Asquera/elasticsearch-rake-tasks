require 'ostruct'

module Elasticsearch
  module Yaml
    class Parser
      NODE_NAME = 'inherit'
      TAG_NAME  = '!file'

      def load_file(file)
        parse_file(file).to_ruby
      end

      def parse_file(file)
        parse_yaml_content(File.read(file))
      rescue StandardError => e
        # STDOUT.puts "Error while reading file #{file}: #{e}"
        raise e
      end

      def parse_yaml_content(content)
        parser = Psych::Parser.new(Elasticsearch::Template::Handler.new(self))
        parser.parse(content).handler.document
      end
    end
  end
end
