module Babushka
  class BugReporter
    # This method creates a bug report for +dep+, by reading the debug log and
    # vars associated with it and posting them as a gist. If the github user is
    # set in the git config, it's marked as from that user, otherwise it's
    # anonymous.
    def self.report dep
      Prompt.confirm "I can file a bug report for that now, if you like.", :default => 'n', :otherwise => "OK, you're on your own :)" do
        post_report dep,
          (ShellHelpers.which('git') && ShellHelpers.shell('git config github.user')) || 'anonymous',
          Base.task.var_path_for(dep).read,
          Base.task.log_path_for(dep).read
      end
    end


    private

    # gist.github.com API example at http://gist.github.com/4277
    def self.post_report dep, user, vars, log
      require 'net/http'
      require 'uri'

      Net::HTTP.post_form(
        URI.parse('http://gist.github.com/api/v1/xml/new'), {
          "files[from]" => user,
          "files[vars.yml]" => vars,
          "files[#{dep.contextual_name}.log]" => (log || '').decolorize
        }
      ).tap {|response|
        report_report_result dep, response
      }.is_a? Net::HTTPSuccess
    end

    def self.report_report_result dep, response
      if response.is_a? Net::HTTPSuccess
        gist_id = (response.body || '').scan(/<repo>(\d+)<\/repo>/).flatten.first
        if gist_id.nil?
          LogHelpers.log_stderr "Done, but the report's URL couldn't be parsed. Here's some info:"
          LogHelpers.log_stderr response.body
        else
          LogHelpers.log "You can view the report at http://gist.github.com/#{gist_id} - thanks :)"
        end
      else
        LogHelpers.log_stderr "Deary me, the bug report couldn't be submitted! Would you mind emailing these two files:"
        LogHelpers.log_stderr '  ' + Base.task.var_path_for(dep)
        LogHelpers.log_stderr '  ' + Base.task.log_path_for(dep)
        LogHelpers.log_stderr "to ben@hoskings.net? Thanks."
      end
    end
  end
end
