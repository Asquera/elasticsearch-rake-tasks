require 'spec_helper'

describe Elasticsearch::Yaml::Parser do
  def mapping_file(template, file)
    "#{examples_root}/#{template}/mappings/#{file}"
  end

  describe "#parse_yaml_file" do
    context "simple template" do
      it "matches hash" do
        filename = mapping_file("simple", "foo.yml")
        subject.parse_yaml_file(filename).to_ruby.should == {
          'title' => {
            'type'     => 'string',
            'analyzer' => 'foo_analyzer'
          }
        }
      end
    end
  end
end
