require 'yaml'

module Elasticsearch
  module Template
    class Compiler
      def self.default_parser
        Psych::Inherit::File::Parser.new
      end

      attr_reader :path
      attr_reader :parser

      def initialize(path, parser = nil)
        @path = path
        @parser = parser || Compiler.default_parser
      end

      def compile(template)
        template_path = "#{path}/#{template}"
        unless File.directory?(template_path)
          raise "Template #{template_path} not a directory"
        end

        template = read_template(template_path)
        result = {}
        result['settings'] = read_settings(template_path)
        result['mappings'] = MappingsReader.new(template_path).read
        result['template'] = template if template
        result
      end

      def read_settings(template_path)
        Dir.chdir(template_path) do
          filename = Dir["settings.{yml,yaml}"].first
          if File.exists?(filename)
            parser.load_file(filename)
          else
            {}
          end
        end
      end

      def read_template(template_path)
        filename = "#{template_path}/template_pattern"
        File.read(filename).chomp
      rescue
        nil
      end
    end
  end
end
