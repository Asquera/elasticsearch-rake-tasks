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

      # private

      # Replaces file include nodes with the content of an external yaml file
      #
      def replace_file_include_nodes(document)
        document.grep(Psych::Nodes::Mapping).each do |n|
          n.children.tap do |nodes|
            find_file_include_nodes(nodes).reverse.each do |node|
              # remove the pair of Scalar nodes
              nodes.delete(node.item)
              nodes.delete(node.file)

              # and replace it with the content from the external yaml
              content = parse_file(node.file.value)
              content.children.each_with_index do |item, index|
                nodes.insert(node.index + index, item)
              end
            end
          end
        end
      end

      def insertion_node?(n, m)
        n.respond_to?(:value) && n.value == NODE_NAME &&
        m.respond_to?(:tag)   && m.tag   == TAG_NAME
      end

      def find_file_include_nodes(nodes)
        result = []
        nodes.each_index do |index|
          m, n = nodes.slice(index, 2)
          if insertion_node?(m, n)
            result << OpenStruct.new(item: m, file: n, index: index)
          end
        end
        result
      end
    end
  end
end
