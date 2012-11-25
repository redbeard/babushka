require 'spec_helper'

describe "version" do
  before {
    LogHelpers.should_receive(:log).with(Base.runtime_info, :debug => true)
    LogHelpers.should_receive(:log).with("#{Babushka::VERSION} (#{Babushka::Base.ref})")
  }
  it "should print the version" do
    Cmdline::Parser.for(%w[version]).run
  end
end
