# frozen_string_literal: true

require 'test_helper'

class TimeTreeClientTest < TimeTreeBaseTest
  def test_initialize
    e =
      assert_raises StandardError do
        TimeTree::Client.new
      end
    assert_equal(TimeTree::Error, e.class)
    assert_equal('token is required.', e.message)

    # set a token by configure
    TimeTree.configure do |config|
      config.token = 'token_from_configure'
    end
    client = TimeTree::Client.new
    assert_equal 'token_from_configure', client.token
  end

  #
  # test for TimeTree::Client#current_user
  #

  def test_fetch_current_user
    user_res_body = load_test_data('user_001.json')
    add_stub_request(:get, "#{HOST}/user", res_body: user_res_body)
    user = @client.current_user
    assert_equal 600, @client.ratelimit_limit
    assert_equal 599, @client.ratelimit_remaining
    assert_equal Time, @client.ratelimit_reset_at.class
    assert_user001 user
  end

  def test_fetch_current_user_then_fail
    res_body = load_test_data('401.json')
    add_stub_request(:get, "#{HOST}/user", res_body: res_body, res_status: 401)
    e =
      assert_raises StandardError do
        @client.current_user
      end
    assert_401_error e
  end

  #
  # test for TimeTree::Client#calendar
  #

  def test_fetch_calendar
    cal = fetch_cal001
    assert_cal001 cal
  end

  def test_fetch_calendar_with_include_options
    cal_res_body = load_test_data('calendar_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendars/CAL001(\?.*)?}, res_body: cal_res_body)
    cal = @client.calendar 'CAL001'

    assert_cal001 cal
    assert_cal001_labels cal.labels
    assert_cal001_members cal.members
  end

  def test_fetch_calendar_then_fail
    res_body = load_test_data('404_calendar.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL_NOT_FOUND", res_body: res_body, res_status: 404)
    e =
      assert_raises StandardError do
        @client.calendar 'CAL_NOT_FOUND', include_relationships: {}
      end
    assert_404_calendar_error e
  end

  def test_fetch_calendars
    cals = fetch_calendars
    assert_equal 2, cals.length
    assert_cal001 cals[0]
    assert_cal002 cals[1]
  end

  def test_fetch_calendars_with_include_options
    res_body = load_test_data('calendars_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendars(\?.*)?}, res_body: res_body)
    cals = @client.calendars

    cal1 = cals[0]
    assert_cal001 cal1
    assert_cal001_labels cal1.labels
    assert_cal001_members cal1.members
    cal2 = cals[1]
    assert_cal002 cal2
    assert_cal002_labels cal2.labels
    assert_cal002_members cal2.members
  end

  def test_fetch_calendars_then_fail
    res_body = load_test_data('401.json')
    add_stub_request(:get, "#{HOST}/calendars", res_body: res_body, res_status: 401)
    e =
      assert_raises StandardError do
        @client.calendars include_relationships: {}
      end
    assert_401_error e
  end

  #
  # test for TimeTree::Client#calendar_members
  #

  def test_fetch_calendar_members
    res_body = load_test_data('calendar_members_001.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/members", res_body: res_body)
    mems = @client.calendar_members 'CAL001'
    assert_cal001_members mems
  end

  def test_fetch_calendar_members_then_fail
    res_body = load_test_data('401.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/members", res_body: res_body, res_status: 401)
    e =
      assert_raises StandardError do
        @client.calendar_members 'CAL001'
      end
    assert_401_error e
  end

  #
  # test for TimeTree::Client#calendar_labels
  #

  def test_fetch_calendar_labels
    res_body = load_test_data('calendar_labels_001.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/labels", res_body: res_body)
    labels = @client.calendar_labels 'CAL001'
    assert_cal001_labels labels
  end

  def test_fetch_calendar_labels_then_fail
    res_body = load_test_data('401.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/labels", res_body: res_body, res_status: 401)
    e =
      assert_raises StandardError do
        @client.calendar_labels 'CAL001'
      end
    assert_401_error e
  end

  #
  # test for TimeTree::Client#event
  #

  def test_fetch_event
    ev = fetch_ev001
    assert_ev001 ev
  end

  def test_fetch_event_with_include_options
    res_body = load_test_data('event_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendars/CAL001/events/EV001(\?.*)?}, res_body: res_body)
    ev = @client.event 'CAL001', 'EV001'
    assert_ev001 ev, include_option: true
  end

  def test_fetch_recurrence_event
    res_body = load_test_data('event_004_recurrence_child.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/events/EV004_CHILD", res_body: res_body)
    ev = @client.event 'CAL001', 'EV004_CHILD', include_relationships: {}
    assert_ev004_child ev

    res_body = load_test_data('event_004_recurrence_parent.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/events/EV004_PARENT", res_body: res_body)
    ev = @client.event 'CAL001', 'EV004_PARENT', include_relationships: {}
    assert_ev004_parent ev
  end

  def test_fetch_event_then_fail
    res_body = load_test_data('404_event.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/events/EV001", res_body: res_body, res_status: 404)
    e =
      assert_raises StandardError do
        @client.event 'CAL001', 'EV001', include_relationships: {}
      end
    assert_404_event_error e
  end

  #
  # test for TimeTree::Client#upcoming_events
  #

  def test_fetch_upcoming_event
    res_body = load_test_data('events_001.json')
    add_stub_request(:get, %r{#{HOST}/calendars/CAL001/upcoming_events\?days=3(.*)?(timezone=Asia/Tokyo)(.*)?}, res_body: res_body)
    evs = @client.upcoming_events 'CAL001', days: 3, timezone: 'Asia/Tokyo', include_relationships: {}
    assert_equal 3, evs.length
    assert_ev001 evs[0]
    assert_ev002 evs[1]
    assert_ev003 evs[2]
  end

  def test_fetch_upcoming_event_with_include_options
    cal_res_body = load_test_data('calendar_001.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001", res_body: cal_res_body)
    cal = @client.calendar 'CAL001', include_relationships: {}
    evs_res_body = load_test_data('events_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendars/CAL001/upcoming_events\?days=7(.*)?(timezone=UTC)(.*)?}, res_body: evs_res_body)
    evs = cal.upcoming_events
    assert_equal 3, evs.length
    assert_ev001 evs[0], include_option: true
    assert_ev002 evs[1], include_option: true
    assert_ev003 evs[2], include_option: true
  end

  def test_fetch_upcoming_event_then_fail
    res_body = load_test_data('401.json')
    add_stub_request(:get, %r{#{HOST}/calendars/CAL001/upcoming_events\?days=3(.*)?(timezone=Asia/Tokyo)(.*)?}, res_body: res_body, res_status: 401)
    e =
      assert_raises StandardError do
        @client.upcoming_events 'CAL001', days: 3, timezone: 'Asia/Tokyo', include_relationships: {}
      end
    assert_401_error e
  end

  #
  # test for TimeTree::Client#create_event
  #

  #
  # test for TimeTree::Client#update_event
  #

  #
  # test for TimeTree::Client#delete_event
  #

  #
  # test for TimeTree::Client#create_activity
  #

  #
  # test for TimeTree::Client#inspect
  #

  def test_inspect
    assert_equal "\#<#{@client.class}:#{@client.object_id}>", @client.inspect
    fetch_cal001
    ratelimit_info = "ratelimit:#{@client.ratelimit_remaining}/#{@client.ratelimit_limit}, reset_at:#{@client.ratelimit_reset_at.strftime('%m/%d %R')}"
    assert_equal "\#<#{@client.class}:#{@client.object_id} #{ratelimit_info}>", @client.inspect
  end

  #
  # TimeTree::Client#update_ratelimit
  #
end
