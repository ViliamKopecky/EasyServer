class EasyHttpResponse
  attr_accessor :server, :headers

  def initialize(server)
    self.server = server
    self.headers = default_headers
  end

  def default_headers
    { "X-Powered-By" => "EasyServer" }
  end

  def default_params(params)
    {:code => 200, :content_type => "text/plain; charset=utf-8", :skip_body => false, :error => false}.merge(params)
  end

  def http_version
    "1.0"
  end

  def code_message(code)
    Helpers.code_message code
  end

  def render_initial_line code
    "HTTP/#{http_version} #{code} #{code_message code}\r\n"
  end

  def render_headers
    str = ""
    headers.each { |key, value| str += "#{key}: #{value}\r\n" }
    return str
  end

  def render_error(code)
    path = server.errorfilepath(code)
    render :file => path, :code => code, :body => "#{code} #{code_message code}", :error => true
  end

  def render(params)
    params = default_params params

    error = params[:error]

    file = params[:file]
    code = params[:code]
    body = params[:body]
    skip_body = params[:skip_body]
    content_type = params[:content_type]

    if not file.nil?
      content = Helpers.file_content file
      if content.is_a? String
        body = content
        content_type = Helpers.ext2mime file
      elsif not error
        return render_error 404
      end
    elsif body.nil?
      return render_error code
    end

    # Chrome and IE need more than 513 B errorfile size
    body = Helpers.sanitize_errorfile_size body unless body.nil?

    headers["Date"] = Helpers.rfc_format_time(Time.now)
    headers["Content-Length"] = body.bytesize unless body.nil?
    headers["Content-Type"] = content_type unless body.nil?

    str = render_initial_line code
    str += render_headers
    str += "\r\n#{body}" unless body.nil? or skip_body

    if body.nil?
      server.log "Response: #{code} #{code_message code}"
    else
      server.log "Response: #{code} #{code_message code} (#{Helpers.bytesize headers["Content-Length"]} of #{headers["Content-Type"]})"
    end

    return str
  end

end