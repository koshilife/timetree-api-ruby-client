# frozen_string_literal: true

require 'test_helper'

class TimeTreeCalendarTest < TimeTreeBaseTest
  def test_model_inspect
    cal = fetch_cal001
    assert_equal "\#<#{cal.class}:#{cal.object_id} id:#{cal.id}>", cal.inspect
  end

  #
  # TimeTree::Calendar
  #

  def test_fetch_event_from_calendar_obj
    cal = fetch_cal001
    ev_res_body = load_test_data('event_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendars/CAL001/events/EV001(\?.*)?}, res_body: ev_res_body)
    ev = cal.event 'EV001'
    assert_ev001 ev, include_option: true
  end

  # upcoming_events

  # labels

  # members
end
