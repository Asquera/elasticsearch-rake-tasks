require 'spec_helper'

describe Elasticsearch::Yaml::Parser do
  let(:parser){ Elasticsearch::Yaml::Parser.new }

  def mapping_folder(template)
    "#{examples_root}/#{template}/mappings"
  end

  describe "#load_file" do
    subject do
      Dir.chdir(dir) do
        parser.load_file(yaml)
      end
    end

    context "missing file" do
      let(:dir){ mapping_folder("simple") }
      let(:yaml){ "#{dir}/unknow.yml" }

      it "raises an error" do
        expect{ subject }.to raise_error
      end
    end

    context "simple template" do
      let(:dir){ mapping_folder("simple") }
      let(:yaml){ "#{dir}/foo.yml" }

      it "does not raise error" do
        expect{ subject }.not_to raise_error
      end

      it "matches hash" do
        subject.should == {
          'title' => {
            'type'     => 'string',
            'analyzer' => 'foo_analyzer'
          }
        }
      end
    end

    context "template with file include" do
      let(:dir){ mapping_folder("simple") }
      let(:yaml){ "#{dir}/bar.yml" }

      it "does not raise error" do
        expect{ subject }.not_to raise_error
      end

      it "matches hash" do
        subject.should == {
          'properties' => {
            'title' => {
              'type'     => 'string',
              'analyzer' => 'foo_analyzer'
            },
            'name' => {
              'type'     => 'string',
              'analyzer' => 'foo_analyzer'
            }
          }
        }
      end
    end

    context "template with external alias" do
      let(:dir){ mapping_folder("include") }
      let(:yaml){ "#{dir}/mixin.yml" }

      it "does not raise error" do
        expect{ subject }.not_to raise_error
      end

      it "matches hash" do
        subject.should == {
          'properties' => {
            'name'    => { 'type' => 'string' },
            'surname' => { 'type' => 'string' }
          }
        }
      end
    end
  end
end
