```ruby title="Ruby"
require 'net/http'
require 'json'
require 'uri'

uri = URI('http://localhost:8000/chunk')

# Basic chunking with defaults
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri.path)
request['Content-Type'] = 'application/json'
request.body = { text: 'Your long text content here...' }.to_json

response = http.request(request)
result = JSON.parse(response.body)
puts "Created #{result['chunk_count']} chunks"

# Chunking with custom configuration
request = Net::HTTP::Post.new(uri.path)
request['Content-Type'] = 'application/json'
request.body = {
  text: 'Your long text content here...',
  chunker_type: 'text',
  config: {
    max_characters: 1000,
    overlap: 50,
    trim: true
  }
}.to_json

response = http.request(request)
result = JSON.parse(response.body)

result['chunks'].each do |chunk|
  preview = chunk['content'][0, 50]
  puts "Chunk #{chunk['chunk_index']}: #{preview}..."
end
```
