# Quiet Hacker - Ruby Preview
require "json"
require "net/http"

module QuietHacker
  VERSION = "1.0.0"
  DEFAULT_TIMEOUT = 30

  class Config
    attr_reader :host, :port, :options

    def initialize(host:, port: 8080, **options)
      @host = host
      @port = port
      @options = options.freeze
    end

    def to_h
      { host: @host, port: @port, **@options }
    end

    def to_s
      "#{@host}:#{@port}"
    end
  end

  class Client
    def initialize(config)
      @config = config
      @connections = {}
      @retries = config.options.fetch(:retries, 3)
    end

    def get(path, headers: {})
      request(:get, path, headers: headers)
    end

    def post(path, body:, headers: {})
      request(:post, path, body: body, headers: headers)
    end

    private

    def request(method, path, body: nil, headers: {})
      attempts = 0
      begin
        attempts += 1
        uri = URI("http://#{@config}/#{path}")
        response = case method
                   when :get  then Net::HTTP.get_response(uri)
                   when :post then Net::HTTP.post(uri, body.to_json, headers)
                   end

        parse_response(response)
      rescue StandardError => e
        retry if attempts < @retries
        { error: e.message, attempts: attempts }
      end
    end

    def parse_response(response)
      case response.code.to_i
      when 200..299
        JSON.parse(response.body, symbolize_names: true)
      when 400..499
        { error: "Client error: #{response.code}" }
      else
        { error: "Server error: #{response.code}" }
      end
    end
  end
end

# Usage
config = QuietHacker::Config.new(host: "localhost", retries: 5)
client = QuietHacker::Client.new(config)

numbers = (1..20).to_a
evens, odds = numbers.partition(&:even?)
squares = numbers.map { |n| n ** 2 }.select { |n| n > 50 }

puts "Config: #{config}"
puts "Evens: #{evens.inspect}"
puts "Large squares: #{squares.inspect}"
