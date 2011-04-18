class EasyHttpRequest

  attr_accessor :server, :socket, :valid, :accepted_at, :headers, :http_method, :path, :fragment, :query, :http_version, :body, :post, :get

  def initialize(server, socket)
    self.server = server
    self.socket = socket
    self.headers = {}
    self.valid = true

    recognize_request
    log_request_info if valid?
  end

  def recognize_request
    begin
      str = socket.recv(4*(1024^2)) # max 4 MB of HTTP Request
      parse_request_string str
    rescue IO::WaitReadable
      IO.select([socket])
      retry
    end
    self.accepted_at = Time.now
  end

  def log_request_info
    str  = "Request: #{http_method} #{path}"
    str += "\n GET: #{get.inspect}" unless get.nil?
    str += "\n POST: #{post.inspect}" unless post.nil?
    server.log str, true
  end

  def parse_request_string(str)
    lines = str.split "\r\n"
    parse_first_line lines.shift
    expect_body = false

    while lines.any? do
      line = lines.shift
      if line == ""
        expect_body = true and break
      else
        parse_header_line line
      end
    end
    
    parse_body lines.join if expect_body
  end

  def get?
    "GET" == http_method
  end

  def head?
    "HEAD" == http_method
  end

  def post?
    "POST" == http_method
  end

  def valid?
    valid
  end

  def parse_body(body)
    self.body = body
    parse_post_data body if post?
  end

  def parse_post_data(str)
    self.post = Helpers.parse_query str
  end

  def parse_first_line(line)
    if line.is_a? String
      line = Helpers.trim line
      # match lines like GET /foo/bar.jpg?key=value HTTP/1.0
      matches = /^([a-z]*)\s+(.*)\s+HTTP\/(1\.0|1\.1)$/i.match line
      unless matches.nil?
        self.http_method = matches[1].upcase  # GET
        self.http_version = matches[3]        # 1.0
        parse_uri matches[2]                  # /foo/bar.jpg?key=value
      else
        self.valid = false
        server.log_error "Unknown HTTP request: #{line.inspect}"
      end
    end
  end

  def parse_header_line line
    line = Helpers.trim line
    matches = /^([a-z0-9\-_\.]*):\s+(.*)$/i.match line
    unless matches.nil?
      identifier = matches[1]
      value = matches[2]
      headers[identifier] = value
    else
      server.log_error "Header line #{line.inspect} did not match regexp."
    end
  end

  def parse_uri(uri)
    uri = Helpers.parse_uri uri
    self.path = uri.path
    self.query = uri.query
    self.get = Helpers.parse_query query
    self.fragment = uri.fragment
  end

  def answer(response)
    response = Helpers.cut_off_body response if head?
    socket.write response
    socket.close
  end

end