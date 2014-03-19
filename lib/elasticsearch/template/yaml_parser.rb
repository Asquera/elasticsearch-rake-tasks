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
        document = parse_yaml_content(File.read(file))
        replace_inherit_node(document)
        document
      rescue StandardError => e
        # STDOUT.puts "Error while reading file #{file}: #{e}"
        raise e
      end

      def parse_yaml_content(content)
        YAML.parse(content).root
      end

      def replace_inherit_node(document)
        document.grep(Psych::Nodes::Mapping).each do |node|
          nodes = node.children
          find_file_include_nodes(nodes).reverse.each do |pair|
            index = nodes.index(pair.item)

            nodes.delete_if{ |n| n == pair.item || n == pair.file }

            content = parse_file(pair.file.value)
            content.children.each do |c|
              nodes.insert(index, c)
              index += 1
            end
          end
        end
      end

      private

      def insertion_node?(n, next_node)
        n.class == Psych::Nodes::Scalar &&
        n.value == NODE_NAME &&
        next_node &&
        next_node.respond_to?(:tag) &&
        next_node.tag == TAG_NAME
      end

      def find_file_include_nodes(nodes)
        nodes.each_index.each_with_object([]) do |index, result|
          m, n = nodes.slice(index, 2)
          if insertion_node?(m, n)
            result << OpenStruct.new(item: m, file: n)
          end
        end
      end
    end
  end
end
