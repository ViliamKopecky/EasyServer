require 'uri'
require 'cgi'

class Helpers

  def Helpers.bytesize(bytes, label_style = 0)
    size = bytes
    suffix = 'Bytes'
    labels = {
      0 => ['KB', 'MB'],
      1 => ['Kilobytes', 'Megabytes'],
      2 => ['KiB', 'MiB']
    }
    sizes = [1024, 1048576, 1073741824]
    
    # KiB
    if size >= 1024
      size = (size / 1024).round
      suffix = labels[label_style][0]
    end
  
    # MiB
    if size >= 1024
      size = (size / 1024).round
      suffix = labels[label_style][1]
    end
    
    size.to_s + ' ' + suffix
  end

  def Helpers.log_format_time(time)
    time.localtime.strftime("%Y/%m/%d %H:%M:%S")
  end

  def Helpers.rfc_format_time(time)
    time.gmtime.strftime("%a, %e %b %Y %H:%M:%S GMT")
  end

  def Helpers.random_string(letters=32)
    (0...letters).map{ ('a'..'z').to_a[rand(26)] }.join
  end

  def Helpers.parse_uri(str)
    URI.parse str if str.is_a? String
  end
  
  def Helpers.parse_query(str)
    CGI.parse str if str.is_a? String
  end

  def Helpers.trim(str)
    str.gsub(/\r\n/, "")
  end

  def Helpers.trim_slashes(str)
    str.gsub(/^\//, "")
  end

  def Helpers.sanitize_path(path)
    path.gsub(/\/$/, "/index.html")
  end

  def Helpers.cut_off_body(str)
    "#{response.split("\r\n\r\n").shift}\r\n"
  end

  def Helpers.ext2mime(filename)
    ext = File.extname(filename)
    case ext
    when ".txt"
      "text/plain; charset=utf-8"
    when ".htm", ".html", ".error"
      "text/html; charset=utf-8"
    when ".css"
      "text/css"
    when ".jpg"
      "image/jpeg"
    when ".gif"
      "image/gif"
    when ".png"
      "image/png"
    when ".ico"
      "image/x-icon"
    when ".pdf"
      "application/pdf"
    else
      "text/plain; charset=utf-8"
    end
  end

  def Helpers.code_message(code)
    case code
    when 100
      "Continue"
    when 200
      "OK"
    when 204
      "No Content"
    when 301
      "Moved Permanently"
    when 400
      "Bad Request"
    when 401
      "Unauthorized"
    when 403
      "Forbidden"
    when 404
      "Not Found"
    when 405
      "Method Not Allowed"
    when 500
      "Internal Server Error"
    when 501
      "Not Implemented"
    when 502
      "Bad Gateway"
    when 503
      "Service Unavailable"
    else
      ""
    end
  end

  def Helpers.file_content(path)
    content = ""
    if File.file?(path)
      File.open(path, "rb") do |infile|
        while (line = infile.gets)
          content += line
        end
      end
      return content
    end
    false
  end

  def Helpers.sanitize_errorfile_size(str)
    if str.is_a? String
      min = 513
      str += " "*(min - str.bytesize) if str.bytesize < min
    end
    return str
  end
end
