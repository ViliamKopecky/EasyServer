require 'socket'
require './classes/server.rb'

host = ARGV[0] || "127.0.0.1"
port = ARGV[1] || 80
base_dir = ARGV[2] || "#{Dir.pwd}/www"

server = EasyServer.new host, port, base_dir
server.use_console_log = false

server.listen