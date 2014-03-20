module Elasticsearch
  module Helpers 
    class Reader
      def initialize(templates_path)
        @templates_path = templates_path
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
        filename = "#{@templates_path}#{mapping}/settings.yaml"
        if File.exist?(filename)
          read_and_parse_file(filename)
        else
          {}
        end
      end

      def read_mappings(mapping)
        mappings = {}

        Dir.chdir("#{@templates_path}#{mapping}/mappings/") do
          paths = Dir['*.{json,yml,yaml}']
          if default_file = paths.find { |f| f =~ /_default\.*/ }
            default = read_and_parse_file(default_file)
            paths.delete default_file
          end

          default ||= {}

          paths.each do |p|
            name, _ = p.split(".")
            content = read_and_parse_file p
            if content.fetch('inherit', true)
              mappings[name] = default.deep_merge(content)
            else
              mappings[name] = content
            end
          end
        end

        mappings
      end

      # reads the template pattern from the file
      # see http://www.elasticsearch.org/guide/reference/api/admin-indices-templates/
      # for usage and format of the template pattern
      def read_template_pattern(mapping)
        filename = "#{@templates_path}#{mapping}/template_pattern"
        if File.exist?(filename)
          File.read(filename).chomp
        else
          nil
        end
      end

      def compile_template_to_string(name)
        JSON.dump compile_template name
      end

      def compile_template(name)
        require 'active_support/core_ext/hash/deep_merge'
        mappings = read_mappings(name)
        settings = read_settings(name)
        template_pattern = read_template_pattern(name)
        output = { "settings" => settings, "mappings" => mappings }
        output['template'] = template_pattern if template_pattern
        output
      end
    end
  end
end
