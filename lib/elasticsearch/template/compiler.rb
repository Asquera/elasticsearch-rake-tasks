require 'yaml'

module Elasticsearch
  module Template
    class Compiler
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def compile(template)
        template_path = "#{path}/#{template}"
        unless File.directory?(template_path)
          raise "Template #{template_path} not a directory"
        end

        result = {}
        result['mappings'] = MappingsReader.new(template_path).read
        result
      end
    end
  end
end
