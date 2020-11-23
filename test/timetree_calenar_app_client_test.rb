# frozen_string_literal: true

require 'test_helper'

class TimeTreeCalendarAppClientTest < TimeTreeBaseTest
  def setup
    pkey = OpenSSL::PKey::RSA.generate(1024).export
    @installation_id = 1
    @client = TimeTree::CalendarApp::Client.new(@installation_id, 'app_id', pkey)
    stub_token_request
  end

  def test_initialize_with_configuration
    pkey = OpenSSL::PKey::RSA.generate(1024).export
    TimeTree.configure do |c|
      c.calendar_app_application_id = 'app_id'
      c.calendar_app_private_key = pkey
    end
    client = TimeTree::CalendarApp::Client.new(1)

    assert_equal 'app_id', client.application_id
    assert_equal pkey, client.private_key.export

    # reset configure
    TimeTree.configure do |c|
      c.calendar_app_application_id = nil
      c.calendar_app_private_key = nil
    end
  end

  def test_initialize_without_installation_id
    e = assert_raises StandardError do
      TimeTree::CalendarApp::Client.new
    end

    assert_equal ArgumentError, e.class
  end

  def test_initialize_without_application_id
    e = assert_raises StandardError do
      pkey = OpenSSL::PKey::RSA.generate(1024).export
      TimeTree::CalendarApp::Client.new(1, nil, pkey)
    end

    assert_equal TimeTree::Error, e.class
    assert_equal 'application_id is required.', e.message
  end

  def test_initialize_without_private_key
    e = assert_raises StandardError do
      TimeTree::CalendarApp::Client.new(1, 'app_id')
    end

    assert_equal TimeTree::Error, e.class
    assert_equal 'private_key must be RSA private key.', e.message
  end

  #
  # test for TimeTree::OAuthApp::Client#calendar
  #

  def test_fetch_calendar
    res_body = load_test_data('calendar_001.json')
    add_stub_request(:get, "#{HOST}/calendar", res_body: res_body)
    cal = @client.calendar include_relationships: {}

    assert_cal001 cal
  end

  def test_fetch_calendar_with_include_options
    res_body = load_test_data('calendar_001_include.json')
    add_stub_request(:get, "#{HOST}/calendar?include=labels,members", res_body: res_body)
    cal = @client.calendar include_relationships: %i[labels members]

    assert_cal001 cal
    assert_cal001_labels cal.labels
    assert_cal001_members cal.members
  end

  def test_calendar_object_of_associated_methods
    res_body = load_test_data('calendar_001.json')
    add_stub_request(:get, "#{HOST}/calendar", res_body: res_body)
    cal = @client.calendar include_relationships: {}

    # Calendar#event
    res_body = load_test_data('event_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendar/events/EV001(\?.*)?}, res_body: res_body)
    ev = cal.event 'EV001'
    assert_ev001 ev, include_option: true, skip_assert_calendar_id: true

    # Calendar#upcoming_events
    res_body = load_test_data('events_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendar/upcoming_events\?days=7(.*)?(timezone=UTC)(.*)?}, res_body: res_body)
    evs = cal.upcoming_events
    assert_equal 3, evs.length
    assert_ev001 evs[0], include_option: true, skip_assert_calendar_id: true
    assert_ev002 evs[1], include_option: true, skip_assert_calendar_id: true
    assert_ev003 evs[2], include_option: true, skip_assert_calendar_id: true

    # Calendar#members
    res_body = load_test_data('calendar_members_001.json')
    add_stub_request(:get, "#{HOST}/calendar/members", res_body: res_body)
    mems = cal.members
    assert_cal001_members mems

    # Calendar#labels
    e = assert_raises(TimeTree::Error) { cal.labels }
    assert_equal 'CalendarApp does not support label api', e.message
  end

  #
  # test for TimeTree::OAuthApp::Client#calendar_members
  #

  def test_fetch_calendar_members
    res_body = load_test_data('calendar_members_001.json')
    add_stub_request(:get, "#{HOST}/calendar/members", res_body: res_body)
    mems = @client.calendar_members

    assert_cal001_members mems
  end

  def test_fetch_calendar_members_then_fail
    res_body = load_test_data('401.json')
    add_stub_request(:get, "#{HOST}/calendar/members", res_body: res_body, res_status: 401)
    e = assert_raises(StandardError) { @client.calendar_members }

    assert_401_error e
  end

  #
  # test for TimeTree::OAuthApp::Client#event
  #

  def test_fetch_event
    res_body = load_test_data('event_001.json')
    add_stub_request(:get, "#{HOST}/calendar/events/EV001", res_body: res_body)
    ev = @client.event 'EV001', include_relationships: {}

    assert_ev001 ev, skip_assert_calendar_id: true
  end

  def test_fetch_event_with_include_options
    res_body = load_test_data('event_001_include.json')
    add_stub_request(:get, "#{HOST}/calendar/events/EV001?include=creator,label,attendees", res_body: res_body)
    ev = @client.event 'EV001', include_relationships: %i[creator label attendees]

    assert_ev001 ev, skip_assert_calendar_id: true, include_option: true
  end

  def test_fetch_recurrence_event
    res_body = load_test_data('event_004_recurrence_child.json')
    add_stub_request(:get, "#{HOST}/calendar/events/EV004_CHILD", res_body: res_body)
    ev = @client.event 'EV004_CHILD', include_relationships: {}

    assert_ev004_child ev, skip_assert_calendar_id: true

    res_body = load_test_data('event_004_recurrence_parent.json')
    add_stub_request(:get, "#{HOST}/calendar/events/EV004_PARENT", res_body: res_body)
    ev = @client.event 'EV004_PARENT', include_relationships: {}

    assert_ev004_parent ev, skip_assert_calendar_id: true
  end

  def test_fetch_event_then_fail
    res_body = load_test_data('404_event.json')
    add_stub_request(:get, "#{HOST}/calendar/events/EV001", res_body: res_body, res_status: 404)
    e = assert_raises(StandardError) { @client.event 'EV001', include_relationships: {} }

    assert_404_event_error e
  end

  def test_fetch_event_then_fail_because_id_is_blank
    e = assert_raises(StandardError) { @client.event nil }

    assert_blank_error e, 'event_id'
  end

  def test_event_object_of_associated_methods
    res_body = load_test_data('event_001.json')
    add_stub_request(:get, "#{HOST}/calendar/events/EV001", res_body: res_body)
    ev = @client.event 'EV001', include_relationships: {}

    # Event#create
    ev2 = ev.dup
    new_title = 'EV001 Title Updated'
    ev2.title = new_title
    res_body = load_test_data('event_001_create.json')
    add_stub_request(:post, "#{HOST}/calendar/events", req_body: ev2.data_params, res_body: res_body, res_status: 201)
    new_ev = ev2.create
    assert_equal 'NEW_EV001', new_ev.id
    assert_ev001 new_ev, skip_assert_id: true, skip_assert_title: true, skip_assert_calendar_id: true

    # Event#update
    ev3 = ev.dup
    ev3.title = 'EV001 Title Updated'
    res_body = load_test_data('event_001_update.json')
    add_stub_request(:put, "#{HOST}/calendar/events/EV001", req_body: ev3.data_params, res_body: res_body)
    updated_ev = ev3.update
    assert_equal ev3.title, updated_ev.title
    assert_ev001 updated_ev, skip_assert_title: true, skip_assert_calendar_id: true

    # Event#create_comment
    ev4 = ev.dup
    message = 'comment1'
    data_params = {data: {attributes: {content: message}}}
    res_body = load_test_data('activity_001_create.json')
    add_stub_request(:post, "#{HOST}/calendar/events/EV001/activities", req_body: data_params, res_body: res_body, res_status: 201)
    activity = ev4.create_comment message
    assert_activity001 activity, skip_assert_calendar_id: true

    # Event#delete
    add_stub_request(:delete, "#{HOST}/calendar/events/EV001", res_status: 204)
    did_delete = ev.delete
    assert did_delete
  end

  #
  # test for TimeTree::OAuthApp::Client#upcoming_events
  #

  def test_fetch_upcoming_event
    res_body = load_test_data('events_001.json')
    add_stub_request(:get, "#{HOST}/calendar/upcoming_events?days=3&timezone=Asia/Tokyo", res_body: res_body)
    evs = @client.upcoming_events days: 3, timezone: 'Asia/Tokyo', include_relationships: {}

    assert_equal 3, evs.length
    assert_ev001 evs[0], skip_assert_calendar_id: true
    assert_ev002 evs[1], skip_assert_calendar_id: true
    assert_ev003 evs[2], skip_assert_calendar_id: true
  end

  def test_fetch_upcoming_event_with_include_options
    res_body = load_test_data('events_001_include.json')
    add_stub_request(:get, "#{HOST}/calendar/upcoming_events?days=3&timezone=Asia/Tokyo&include=creator,label,attendees", res_body: res_body)
    evs = @client.upcoming_events days: 3, timezone: 'Asia/Tokyo', include_relationships: %i[creator label attendees]

    assert_equal 3, evs.length
    assert_ev001 evs[0], include_option: true, skip_assert_calendar_id: true
    assert_ev002 evs[1], include_option: true, skip_assert_calendar_id: true
    assert_ev003 evs[2], include_option: true, skip_assert_calendar_id: true
  end

  def test_fetch_upcoming_event_then_fail
    res_body = load_test_data('401.json')
    add_stub_request(:get, "#{HOST}/calendar/upcoming_events?days=3&timezone=Asia/Tokyo", res_body: res_body, res_status: 401)
    e = assert_raises(StandardError) { @client.upcoming_events days: 3, timezone: 'Asia/Tokyo', include_relationships: {} }

    assert_401_error e
  end

  #
  # test for TimeTree::OAuthApp::Client#create_event
  #

  def test_create_event
    req_body = {data: 'hoge'}
    res_body = load_test_data('event_001_create.json')
    add_stub_request(:post, "#{HOST}/calendar/events", req_body: req_body, res_body: res_body, res_status: 201)
    ev = @client.create_event req_body

    assert_equal 'NEW_EV001', ev.id
    assert_ev001 ev, skip_assert_id: true, skip_assert_title: true, skip_assert_calendar_id: true
  end

  def test_create_event_then_fail
    req_body = {data: 'hoge'}
    res_body = load_test_data('401.json')
    add_stub_request(:post, "#{HOST}/calendar/events", req_body: req_body, res_body: res_body, res_status: 401)
    e = assert_raises(StandardError) { @client.create_event req_body }

    assert_401_error e
  end

  #
  # test for TimeTree::OAuthApp::Client#update_event
  #

  def test_update_event
    req_body = {data: 'hoge'}
    res_body = load_test_data('event_001_update.json')
    add_stub_request(:put, "#{HOST}/calendar/events/EV001", req_body: req_body, res_body: res_body)
    ev = @client.update_event 'EV001', req_body

    assert_equal ev.title, 'EV001 Title Updated'
    assert_ev001 ev, skip_assert_title: true, skip_assert_calendar_id: true
  end

  def test_update_event_then_fail
    req_body = {data: 'hoge'}
    res_body = load_test_data('401.json')
    add_stub_request(:put, "#{HOST}/calendar/events/EV001", req_body: req_body, res_body: res_body, res_status: 401)
    e = assert_raises(StandardError) { @client.update_event 'EV001', req_body }

    assert_401_error e
  end

  def test_update_event_then_fail_because_id_is_blank
    e = assert_raises(StandardError) { @client.update_event nil, {} }
    assert_blank_error e, 'event_id'
  end

  #
  # test for TimeTree::OAuthApp::Client#delete_event
  #

  def test_delete_event
    add_stub_request(:delete, "#{HOST}/calendar/events/EV001", res_status: 204)
    did_delete = @client.delete_event 'EV001'

    assert did_delete
  end

  def test_delete_event_then_fail
    res_body = load_test_data('401.json')
    add_stub_request(:delete, "#{HOST}/calendar/events/EV001", res_body: res_body, res_status: 401)
    e = assert_raises(StandardError) { @client.delete_event 'EV001' }

    assert_401_error e
  end

  def test_delete_event_then_fail_because_id_is_blank
    e = assert_raises(StandardError) { @client.delete_event nil }

    assert_blank_error e, 'event_id'
  end

  #
  # test for TimeTree::OAuthApp::Client#create_activity
  #

  def test_create_activity
    req_body = {data: 'hoge'}
    res_body = load_test_data('activity_001_create.json')
    add_stub_request(:post, "#{HOST}/calendar/events/EV001/activities", req_body: req_body, res_body: res_body, res_status: 201)
    act = @client.create_activity 'EV001', req_body

    assert_activity001 act, skip_assert_calendar_id: true
  end

  def test_create_activity_then_fail
    req_body = {data: 'hoge'}
    res_body = load_test_data('401.json')
    add_stub_request(:post, "#{HOST}/calendar/events/EV001/activities", req_body: req_body, res_body: res_body, res_status: 401)
    e = assert_raises(StandardError) { @client.create_activity 'EV001', req_body }

    assert_401_error e
  end

  def test_create_activity_then_fail_because_id_is_blank
    e = assert_raises(StandardError) { @client.create_activity nil, {} }

    assert_blank_error e, 'event_id'
  end

  #
  # test for TimeTree::OAuthApp::Client#inspect
  #

  def test_inspect
    assert_equal "\#<#{@client.class}:#{@client.object_id}>", @client.inspect

    add_stub_request(:get, "#{HOST}/calendar", res_body: load_test_data('calendar_001.json'))
    @client.calendar include_relationships: {}

    ratelimit_info = "ratelimit:#{@client.ratelimit_remaining}/#{@client.ratelimit_limit}, reset_at:#{@client.ratelimit_reset_at.strftime('%m/%d %R')}"
    assert_equal "\#<#{@client.class}:#{@client.object_id} #{ratelimit_info}>", @client.inspect
  end

private

  def stub_token_request
    res_body = {access_token: 'token', expire_at: Time.now.to_i + 600, token_type: 'Bearer'}.to_json
    stub_request(:post, "#{HOST}/installations/#{@installation_id}/access_tokens").
      with(headers: {'Accept' => 'application/vnd.timetree.v1+json', 'Authorization' => /^Bearer .+/}).
      to_return(status: 200, body: res_body, headers: default_response_headers)
  end
end
