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
        { 'foo' => 1 }
      end
    end
  end
end
