require 'spec_helper'

describe Elasticsearch::Template::Compiler do
  let(:root){ examples_root }

  describe "#initialize" do
    it "creates object" do
      expect{ described_class.new('') }.to_not raise_error
    end
  end

  describe "#compile" do
    context "with missing template" do
      subject{ described_class.new(root) }

      it "raises an error" do
        expect{ subject.compile('unknown') }.to raise_error
      end
    end

    context "with existing template" do
      let(:template){ 'simple' }
      subject{ described_class.new(root) }

      it "does not raise an error" do
        expect{ subject.compile(template) }.to_not raise_error
      end
    end
  end

  describe "compiling simple template" do
    let(:template){ 'simple' }
    subject{ described_class.new(root).compile(template) }

    it "contains mappings entry" do
      subject['mappings'].should_not be_nil
    end
  end
end
