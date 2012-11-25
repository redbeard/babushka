module Babushka
  module ResourceHelpers
    # Make these helpers directly callable, and private when included.
    module_function

    def get url, &block
      Babushka::Resource.get url, &block
    end

    def extract url, &block
      Babushka::Resource.extract url, &block
    end
  end

  class Resource
    def self.get url, &block
      filename = URI.unescape(url.to_s).p.basename
      if filename.to_s.blank?
        LogHelpers.log_error "Not a valid URL to download: #{url}"
      elsif url.to_s[%r{^git://}]
        GitHelpers.git(url, &block)
      else
        download_path = PathHelpers.in_download_dir {|path|
          downloaded_file = download(url, filename)
          path / downloaded_file if downloaded_file
        }
        block.call download_path unless download_path.nil?
      end
    end

    def self.extract url, &block
      get url do |download_path|
        PathHelpers.in_build_dir {
          Asset.for(download_path).extract(&block)
        }
      end
    end

    def self.download url, filename = url.to_s.p.basename
      if filename.p.exists? && !filename.p.empty?
        LogHelpers.log_ok "Already downloaded #{filename}."
        filename
      elsif (result = ShellHelpers.shell(%Q{curl -I -X GET "#{url}"})).nil?
        LogHelpers.log_error "Couldn't download #{url}: `curl` exited with non-zero status."
      else
        response_code = result.val_for(/HTTP\/1\.\d/) # not present for ftp://, etc.
        if response_code && response_code[/^[23]/].nil?
          LogHelpers.log_error "Couldn't download #{url}: #{response_code}."
        elsif !(location = result.val_for('Location')).nil?
          LogHelpers.log "Following redirect from #{url}"
          download URI.escape(location), location.p.basename
        else
          success = LogHelpers.log_block "Downloading #{url}" do
            ShellHelpers.shell('curl', '-#', '-o', "#{filename}.tmp", url.to_s, :progress => /[\d\.]+%/) &&
            ShellHelpers.shell('mv', '-f', "#{filename}.tmp", filename)
          end
          filename if success
        end
      end
    end

  end
end
