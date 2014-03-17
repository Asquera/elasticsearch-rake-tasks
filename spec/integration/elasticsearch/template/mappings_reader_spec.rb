require 'spec_helper'

describe Elasticsearch::Template::MappingsReader do
  let(:template){ 'simple' }

  describe "#initialize" do
    it "creates object with path" do
      expect{ Elasticsearch::Template::MappingsReader.new('') }.to_not raise_error
    end
  end

  describe "reading simple template" do
    let(:path){ "#{examples_root}/#{template}" }
    subject{ Elasticsearch::Template::MappingsReader.new(path).read }

    it "contains a type named 'foo'" do
      subject['foo'].should_not be_nil
    end

    it "contains a type named 'bar'" do
      subject['bar'].should_not be_nil
    end

    context "type 'foo'" do
      it "matches hash" do
        subject['foo'].should == {
          'properties' => {
            'title' => {
              'type'     => 'string',
              'analyzer' => 'foo_analyzer'
            }
          }
        }
      end
    end

    context "type 'bar' with inheritance" do
      it "matches hash" do
        subject['bar'].should == {
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
  end

  describe "reading include template" do
    let(:path){ "#{examples_root}/include" }
    subject{ Elasticsearch::Template::MappingsReader.new(path).read }

    context "type 'mixin'" do
      it "matches hash" do
        subject['mixin'].should == {
          'properties' => {
            'name'    => { 'type' => 'string' },
            'surname' => { 'type' => 'string' }
          }
        }
      end
    end
  end
end
