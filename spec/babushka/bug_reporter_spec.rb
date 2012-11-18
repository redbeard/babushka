require 'spec_helper'

describe BugReporter do
  before {
    Prompt.should_receive(:get_value).and_return('y')
  }

  let(:a_dep) { dep('a reportable dep') }

  it "should post the bug report" do
    stub_uri! [:post, 'http://gist.github.com/api/v1/xml/new'] => [200, {}, ""]
    BugReporter.report(a_dep)
  end

  context "when posting succeeds" do
    it "should log" do
      stub_uri! [:post, 'http://gist.github.com/api/v1/xml/new'] => [200, {}, "<repo>123</repo>"]
      LogHelpers.should_receive(:log)
      BugReporter.report(a_dep)
    end
  end

  context "when posting succeeds" do
    it "should log an error" do
      stub_uri! [:post, 'http://gist.github.com/api/v1/xml/new'] => [200, {}, "lawl"]
      LogHelpers.should_receive(:log_stderr).at_least(1).times
      BugReporter.report(a_dep)
    end
  end

  context "when posting fails" do
    it "should log an error" do
      stub_uri! [:post, 'http://gist.github.com/api/v1/xml/new'] => [400, {}, ""]
      LogHelpers.should_receive(:log_stderr).at_least(1).times
      BugReporter.report(a_dep)
    end
  end
end
