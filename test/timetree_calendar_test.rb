# frozen_string_literal: true

require 'test_helper'

class TimeTreeCalendarTest < TimeTreeBaseTest
  def setup
    super
    @cal = fetch_cal001
    params = {
      id: 'NO_CLIENT_CAL001',
      type: 'calendar'
    }
    @no_client_cal = TimeTree::Calendar.new(**params)
  end

  def test_model_inspect
    assert_equal "\#<#{@cal.class}:#{@cal.object_id} id:#{@cal.id}>", @cal.inspect
  end

  #
  # test for TimeTree::Calendar#event
  #

  def test_fetch_event
    res_body = load_test_data('event_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendars/CAL001/events/EV001(\?.*)?}, res_body: res_body)
    ev = @cal.event 'EV001'
    assert_ev001 ev, include_option: true
  end

  def test_fetch_event_then_fail
    e =
      assert_raises StandardError do
        @no_client_cal.event 'EV001'
      end
    assert_client_nil_error e
  end

  #
  # test for TimeTree::Calendar#upcoming_events
  #

  def test_fetch_upcoming_events
    res_body = load_test_data('events_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendars/CAL001/upcoming_events\?days=7(.*)?(timezone=UTC)(.*)?}, res_body: res_body)
    evs = @cal.upcoming_events
    assert_equal 3, evs.length
    assert_ev001 evs[0], include_option: true
    assert_ev002 evs[1], include_option: true
    assert_ev003 evs[2], include_option: true
  end

  def test_fetch_upcoming_events_then_fail
    e =
      assert_raises StandardError do
        @no_client_cal.upcoming_events
      end
    assert_client_nil_error e
  end

  #
  # test for TimeTree::Calendar#members
  #

  def test_fetch_members
    res_body = load_test_data('calendar_members_001.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/members", res_body: res_body)
    mems = @cal.members
    assert_cal001_members mems
  end

  def test_fetch_members_then_fail
    e =
      assert_raises StandardError do
        @no_client_cal.members
      end
    assert_client_nil_error e
  end

  #
  # test for TimeTree::Calendar#labels
  #

  def test_fetch_labels
    res_body = load_test_data('calendar_labels_001.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/labels", res_body: res_body)
    labels = @cal.labels
    assert_cal001_labels labels
  end

  def test_fetch_labels_then_fail
    e =
      assert_raises StandardError do
        @no_client_cal.labels
      end
    assert_client_nil_error e
  end
end
