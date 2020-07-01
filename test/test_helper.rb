# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'simplecov'
SimpleCov.start
if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use!
require 'webmock/minitest'

require 'timetree'
require 'assert_helper'

class TimeTreeBaseTest < Minitest::Test
  include AssertHelper

  HOST = TimeTree::Client::API_HOST

  def setup
    @client = TimeTree::Client.new('token')
  end

  private

  def default_request_headers(token = 'token')
    { 'Accept' => 'application/vnd.timetree.v1+json', 'Authorization' => "Bearer #{token}" }
  end

  def default_response_headers
    now = Time.new
    {
      'Content-Type' => 'application/json; charset=utf-8',
      'X-RateLimit-Limit' => 600,
      'X-RateLimit-Remaining' => 599,
      'X-RateLimit-Reset' => (now.to_i + 60 * 10)
    }
  end

  def fetch_cal001
    res_body = load_test_data('calendar_001.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001", res_body: res_body)
    @client.calendar 'CAL001', include_relationships: {}
  end

  def fetch_ev001
    res_body = load_test_data('event_001.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/events/EV001", res_body: res_body)
    @client.event 'CAL001', 'EV001', include_relationships: {}
  end

  def fetch_calendars
    res_body = load_test_data('calendars_001.json')
    add_stub_request(:get, "#{HOST}/calendars", res_body: res_body)
    @client.calendars include_relationships: {}
  end

  def load_test_data(filename)
    filepath = File.join(File.dirname(__FILE__), 'testdata', filename)
    file = File.new(filepath)
    file.read
  end

  def add_stub_request(method, url, req_body: nil, req_headers: nil, res_status: nil, res_body: nil, res_headers: nil)
    WebMock.enable!
    req_headers ||= default_request_headers
    res_headers ||= default_response_headers
    res_status ||= 200
    stub_request(method, url).with(body: req_body, headers: req_headers).to_return(status: res_status, body: res_body, headers: res_headers)
  end
end
