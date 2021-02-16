require 'http/2'
require 'uri'
require 'socket'
require 'logger'

options = {
  # payload: "Everything is awesome"
}

uri = URI.parse('http://localhost:4000/')
sock = TCPSocket.new(uri.host, uri.port)

conn = HTTP2::Client.new

stream = conn.new_stream
log = Logger.new(stream.id)

conn.on(:frame) do |bytes|
  puts "Sending bytes: #{bytes.unpack("H*").first}"
  sock.print bytes
  sock.flush
end

conn.on(:frame_sent) do |frame|
  puts "Sent frame: #{frame.inspect}"
end

conn.on(:frame_received) do |frame|
  puts "Received frame: #{frame.inspect}"
end

conn.on(:promise) do |promise|
  promise.on(:promise_headers) do |h|
    log.info "promise request headers: #{h}"
  end

  promise.on(:headers) do |h|
    log.info "promise headers: #{h}"
  end

  promise.on(:data) do |d|
    log.info "promise data chunk: <<#{d.size}>>"
  end
end

conn.on(:altsvc) do |f|
  log.info "received ALTSVC #{f}"
end

stream.on(:close) do
  log.info 'stream closed'
end

stream.on(:half_close) do
  log.info 'closing client-end of the stream'
end

stream.on(:headers) do |h|
  log.info "response headers: #{h}"
end

stream.on(:data) do |d|
  log.info "response data chunk: <<#{d}>>"
end

stream.on(:altsvc) do |f|
  log.info "received ALTSVC #{f}"
end

head = {
  ':scheme' => uri.scheme,
  ':method' => (options[:payload].nil? ? 'GET' : 'POST'),
  ':authority' => [uri.host, uri.port].join(':'),
  ':path' => uri.path,
  'accept' => '*/*',
}

puts 'Sending HTTP 2.0 request'
if head[':method'] == 'GET'
  stream.headers(head, end_stream: true)
else
  stream.headers(head, end_stream: false)
  stream.data(options[:payload])
end

while !sock.closed? && !sock.eof?
  data = sock.read_nonblock(1024)
  puts "Received bytes: #{data.unpack("H*").first}"

  begin
    conn << data
  rescue StandardError => e
    puts "#{e.class} exception: #{e.message} - closing socket."
    e.backtrace.each { |l| puts "\t" + l }
    sock.close
  end
end
