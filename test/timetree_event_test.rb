# frozen_string_literal: true

require 'test_helper'

class TimeTreeEventTest < TimeTreeBaseTest
  def test_model_inspect
    cal = fetch_cal001
    assert_equal "\#<#{cal.class}:#{cal.object_id} id:#{cal.id}>", cal.inspect
  end

  # create

  # Model Event#create
  def test_create_event
    ev = fetch_ev001
    new_ev = ev.dup
    new_title = 'NEW_EV001 Title'
    new_ev.title = new_title

    ev_res_body = load_test_data('event_001_create.json')
    add_stub_request(:post, "#{HOST}/calendars/CAL001/events", req_body: new_ev.data_params, res_status: 201, res_body: ev_res_body)
    new_ev = new_ev.create
    assert_equal 'NEW_EV001', new_ev.id
    assert_equal new_title, new_ev.title

    new_ev.title = ev.title
    assert_ev001 new_ev, skip_assert_id: true
  end

  # update

  # Model Event#update
  def test_update_event
    ev = fetch_ev001
    before_ev = ev.dup
    update_title = 'EV001 Title Updated'
    ev.title = update_title
    ev_res_body = load_test_data('event_001_update.json')
    add_stub_request(:put, "#{HOST}/calendars/CAL001/events/EV001", req_body: ev.data_params, res_body: ev_res_body)
    updated_ev = ev.update
    assert_equal update_title, updated_ev.title

    updated_ev.title = before_ev.title
    assert_ev001 updated_ev
  end

  # delete

  # Model Event#delete
  def test_delete_event
    ev = fetch_ev001
    add_stub_request(:delete, "#{HOST}/calendars/CAL001/events/EV001", res_status: 204)
    assert ev.delete
  end

  # create_comment

  # Model Event#create_comment
  def test_create_activity
    ev = fetch_ev001

    message = 'New Comment!'
    data_params = { data: { attributes: { content: message } } }

    act_res_body = load_test_data('activity_001_create.json')
    add_stub_request(:post, "#{HOST}/calendars/CAL001/events/EV001/activities", req_body: data_params, res_status: 201, res_body: act_res_body)

    activity = ev.create_comment(message)
    assert_activity001 activity
  end

  # data_params
end
