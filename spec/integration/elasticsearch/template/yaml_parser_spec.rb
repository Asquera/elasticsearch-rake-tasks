require 'spec_helper'

describe Elasticsearch::Yaml::Parser do
  let(:parser){ Elasticsearch::Yaml::Parser.new }

  def mapping_folder(template)
    "#{examples_root}/#{template}/mappings"
  end

  describe "#parse_yaml_file" do
    subject do
      Dir.chdir(dir) do
        parser.parse_yaml_file(yaml)
      end
    end

    context "simple template" do
      let(:dir){ mapping_folder("simple") }
      let(:yaml){ "#{dir}/foo.yml" }

      it "does not raise error" do
        expect{ subject.to_ruby }.not_to raise_error
      end

      it "matches hash" do
        subject.to_ruby.should == {
          'title' => {
            'type'     => 'string',
            'analyzer' => 'foo_analyzer'
          }
        }
      end
    end

    context "template with file incldue" do
      let(:dir){ mapping_folder("include") }
      let(:yaml){ "#{dir}/mixin.yml" }

      it "does not raise error" do
        expect{ subject.to_ruby }.not_to raise_error
      end

      it "matches hash" do
        subject.to_ruby.should == {
          'properties' => {
            'name'    => { 'type' => 'string' },
            'surname' => { 'type' => 'string' }
          }
        }
      end
    end
  end
end
