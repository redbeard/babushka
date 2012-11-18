def stub_uri! pairs
  pairs.each_pair {|request,response|
    body = if response[2].blank? || response[2][/^\{.*\}$/] # if it looks like a JSON object
      response[2]
    elsif File.file?(File.join("spec/support/responses", response[2]))
      File.read(File.join("spec/support/responses", response[2]))
    else
      response[2].to_s
    end

    # Request: [method, uri], e.g. [:get, '/articles.json']
    # Response: [status, headers, body], like rack, e.g. [200, {}, 'hello!']
    WebMock.stub_request(request[0], request[1]).to_return(
      :status => response[0], :headers => response[1], :body => body
    )
  }
end
