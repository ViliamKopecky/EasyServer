require 'socket'
require './classes/helpers.rb'
require './classes/request.rb'
require './classes/response.rb'

class EasyServer

  attr_accessor :server, :host, :port, :base_dir, :use_console_log

  def initialize(host, port, base_dir)
    self.host = host
    self.port = port
    self.base_dir = base_dir
    self.use_console_log = true
  end

  def start
    self.server = TCPServer.new self.host, self.port
    listen
  end

  def close
    self.server.close
  end

  def listen
    start if self.server.nil?

    loop do
      Thread.start(accept) do |socket|
        process socket
      end
    end
  end

  def accept
    self.server.accept
  end

  def process(socket)
    request = build_request socket
    response = build_response

    if request.valid? # if recognized known request
      path = Helpers.sanitize_path(request.path)
      if request.post? # not implemented processing POST data
        request.answer response.render :code => 501
      else
        request.answer response.render :file => filepath(path)
      end
    else
      request.answer response.render :code => 400
    end

  rescue => e
    bt = e.backtrace.join("\n ")
    log_error "#{e.inspect}\n #{bt}"
  end

  def build_request socket
    EasyHttpRequest.new self, socket
  end

  def build_response
    EasyHttpResponse.new self
  end

  ## logging

  def log(message, rule=false)
    console_log message, rule if self.use_console_log
    file_log message, rule
  end

  def log_error(message, rule=true)
    log "ERROR! #{message}"
  end

  def log_rule
    time_string = Helpers.log_format_time(Time.now)
    "\n- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - #{time_string}"
  end

  def format_log_message(message, rule=false)
    if rule
      "#{log_rule}\n#{message}\n"
    else
      "#{message}\n"
    end
  end

  def console_log(message, rule=false)
    puts format_log_message message, rule
  end

  def file_log(message, rule=false)
    logfile = filepath "log.txt"
    file = File.open logfile, "a+"
    file.puts format_log_message message, rule
    file.close
  end

  ## files

  def filepath(file)
    "#{base_dir}/#{Helpers.trim_slashes file}"
  end

  def errorfilepath(code)
    filepath "#{code}.error"
  end
  
end
