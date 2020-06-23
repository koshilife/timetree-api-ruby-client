# frozen_string_literal: true

require 'test_helper'

require 'time'

class ClientTest < Minitest::Test
  HOST = TimeTree::Client::API_HOST

  def setup
    @client = TimeTree::Client.new('token')
  end

  def test_fetch_current_user
    user_res_body = load_test_data('user_001.json')
    add_stub_request(:get, "#{HOST}/user", res_body: user_res_body)
    user = @client.current_user
    assert_equal 600, @client.ratelimit_limit
    assert_equal 599, @client.ratelimit_remaining
    assert_equal Time, @client.ratelimit_reset_at.class
    assert_user001 user
  end

  def test_fetch_calendars
    cals_res_body = load_test_data('calendars_001.json')
    add_stub_request(:get, %r{#{HOST}/calendars(\?.*)?}, res_body: cals_res_body)
    cals = @client.calendars
    assert_equal 2, cals.length

    cal1 = cals[0]
    assert_cal001 cal1
    cal2 = cals[1]
    assert_cal002 cal2

    # fetch related labels data
    labels_res_body = load_test_data('calendar_labels_001.json')
    add_stub_request(:get, "#{HOST}/calendars/#{cal1.id}/labels", res_body: labels_res_body)
    labels = cal1.labels
    assert_cal001_labels labels

    # fetch relation labels
    mems_res_body = load_test_data('calendar_members_001.json')
    add_stub_request(:get, "#{HOST}/calendars/#{cal1.id}/members", res_body: mems_res_body)
    mems = cal1.members
    assert_cal001_members mems
  end

  def test_fetch_calendars_with_include_options
    cals_res_body = load_test_data('calendars_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendars(\?.*)?}, res_body: cals_res_body)
    cals = @client.calendars
    assert_equal 600, @client.ratelimit_limit
    assert_equal 599, @client.ratelimit_remaining
    assert_equal Time, @client.ratelimit_reset_at.class
    assert_equal 2, cals.length

    cal1 = cals[0]
    assert_cal001 cal1
    assert_cal001_labels cal1.labels
    assert_cal001_members cal1.members
    cal2 = cals[1]
    assert_cal002 cal2
    assert_cal002_labels cal2.labels
    assert_cal002_members cal2.members
  end

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

  def test_fetch_event
    ev = fetch_ev001
    assert_ev001 ev
  end

  def test_fetch_event_with_include_options
    ev_res_body = load_test_data('event_001_include.json')
    add_stub_request(:get, %r{#{HOST}/calendars/CAL001/events/EV001(\?.*)?}, res_body: ev_res_body)
    ev = @client.event 'CAL001', 'EV001'
    assert_ev001 ev, include_option: true
  end

  def test_fetch_upcoming_event
    cal = fetch_cal001
    evs_res_body = load_test_data('events_001.json')
    add_stub_request(:get, %r{#{HOST}/calendars/CAL001/upcoming_events\?days=3(.*)?(timezone=Asia/Tokyo)(.*)?}, res_body: evs_res_body)
    evs = cal.upcoming_events(days: 3, timezone: 'Asia/Tokyo')
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

  def test_delete_event
    ev = fetch_ev001
    add_stub_request(:delete, "#{HOST}/calendars/CAL001/events/EV001", res_status: 204)
    assert ev.delete
  end

  def test_create_activity
    ev = fetch_ev001

    message = 'New Comment!'
    data_params = { data: { attributes: { content: message } } }

    act_res_body = load_test_data('activity_001_create.json')
    add_stub_request(:post, "#{HOST}/calendars/CAL001/events/EV001/activities", req_body: data_params, res_status: 201, res_body: act_res_body)

    activity = ev.create_comment(message)
    assert_activity001 activity
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

  def add_stub_request(method, url, req_body: nil, req_headers: nil, res_status: nil, res_body: nil, res_headers: nil)
    WebMock.enable!
    req_headers ||= default_request_headers
    res_headers ||= default_response_headers
    res_status ||= 200
    stub_request(method, url).with(body: req_body, headers: req_headers).to_return(status: res_status, body: res_body, headers: res_headers)
  end

  def load_test_data(filename)
    filepath = File.join(File.dirname(__FILE__), 'testdata', filename)
    file = File.new(filepath)
    file.read
  end

  def fetch_cal001
    cal_res_body = load_test_data('calendar_001.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001", res_body: cal_res_body)
    @client.calendar 'CAL001', include_relationships: {}
  end

  def fetch_ev001
    ev_res_body = load_test_data('event_001.json')
    add_stub_request(:get, "#{HOST}/calendars/CAL001/events/EV001", res_body: ev_res_body)
    @client.event 'CAL001', 'EV001', include_relationships: {}
  end

  def assert_cal001(cal)
    assert_equal 'CAL001', cal.id
    assert_equal 'calendar', cal.type
    assert_equal 'CalName001', cal.name
    assert_equal Time.parse('2020-05-01T09:00:00.000Z').to_i, cal.created_at.to_i
    assert_equal 'CalName001 Description', cal.description
    assert_equal 'https://attachments.timetreeapp.com/CalName001.jpg', cal.image_url
    assert_equal '#000001', cal.color
    label_ids = cal.relationships[:labels].map { |d| d[:id] }
    assert_equal %w[CAL001,1 CAL001,2 CAL001,3 CAL001,4 CAL001,5 CAL001,6 CAL001,7 CAL001,8 CAL001,9 CAL001,10], label_ids
    member_ids = cal.relationships[:members].map { |d| d[:id] }
    assert_equal %w[CAL001,USER001 CAL001,USER002], member_ids
  end

  def assert_cal001_labels(labels)
    assert_equal 10, labels.length
    f_label = labels.first
    assert_equal 'CAL001,1', f_label.id
    assert_equal 'label', f_label.type
    assert_equal 'Emerald green', f_label.name
    assert_equal '#2ecc87', f_label.color
    l_label = labels.last
    assert_equal 'CAL001,10', l_label.id
    assert_equal 'label', l_label.type
    assert_equal 'Soft violet', l_label.name
    assert_equal '#b38bdc', l_label.color
  end

  def assert_user001(user)
    assert_equal 'CAL001,USER001', user.id
    assert_equal 'user', user.type
    assert_equal 'USER001 Name', user.name
    assert_equal 'USER001 Description', user.description
    assert_equal 'https://attachments.timetreeapp.com/USER001.png', user.image_url
  end

  def assert_user002(user)
    assert_equal 'CAL001,USER002', user.id
    assert_equal 'user', user.type
    assert_equal 'USER002 Name', user.name
    assert_equal 'USER002 Description', user.description
    assert_equal 'https://attachments.timetreeapp.com/USER002.png', user.image_url
  end

  def assert_cal001_members(mems)
    assert_equal 2, mems.length
    assert_user001 mems.first
    assert_user002 mems.last
  end

  def assert_cal002(cal)
    assert_equal 'CAL002', cal.id
    assert_equal 'calendar', cal.type
    assert_equal 'CalName002', cal.name
    assert_equal Time.parse('2020-06-01T09:00:00.000Z').to_i, cal.created_at.to_i
    assert_equal 'CalName002 Description', cal.description
    assert_equal 'https://attachments.timetreeapp.com/CalName002.jpg', cal.image_url
    assert_equal '#000002', cal.color
    label_ids = cal.relationships[:labels].map { |d| d[:id] }
    assert_equal %w[CAL002,1 CAL002,2 CAL002,3 CAL002,4 CAL002,5 CAL002,6 CAL002,7 CAL002,8 CAL002,9 CAL002,10], label_ids
    member_ids = cal.relationships[:members].map { |d| d[:id] }
    assert_equal %w[CAL002,USER001], member_ids
  end

  def assert_cal002_labels(labels)
    assert_equal 10, labels.length
    f_label = labels.first
    assert_equal 'CAL002,1', f_label.id
    assert_equal 'label', f_label.type
    assert_equal 'Emerald green', f_label.name
    assert_equal '#2ecc87', f_label.color
    l_label = labels.last
    assert_equal 'CAL002,10', l_label.id
    assert_equal 'label', l_label.type
    assert_equal 'Soft violet', l_label.name
    assert_equal '#b38bdc', l_label.color
  end

  def assert_cal002_members(mems)
    assert_equal 1, mems.length
    f_mem = mems.first
    assert_equal 'CAL002,USER001', f_mem.id
    assert_equal 'user', f_mem.type
    assert_equal 'USER001 Name', f_mem.name
    assert_equal 'USER001 Description', f_mem.description
    assert_equal 'https://attachments.timetreeapp.com/USER001.png', f_mem.image_url
  end

  def assert_ev001(ev, include_option: false, skip_assert_id: false)
    assert_equal 'EV001', ev.id unless skip_assert_id
    assert_equal 'event', ev.type
    assert_equal 'EV001 Title', ev.title
    assert_equal 'schedule', ev.category
    assert_equal false, ev.all_day
    assert_equal Time.parse('2020-06-20T10:00:00.000Z').to_i, ev.start_at.to_i
    assert_equal 'Asia/Tokyo', ev.start_timezone
    assert_equal Time.parse('2020-06-20T11:00:00.000Z').to_i, ev.end_at.to_i
    assert_equal 'Asia/Tokyo', ev.end_timezone
    assert_nil ev.recurrences
    assert_nil ev.recurring_uuid
    assert_nil ev.description
    assert_equal 'EV001 Location', ev.location
    assert_equal 'https://github.com', ev.url
    assert_equal Time.parse('2020-06-18T09:00:00.000Z').to_i, ev.updated_at.to_i
    assert_equal Time.parse('2020-06-18T09:00:00.000Z').to_i, ev.created_at.to_i
    assert_equal 'CAL001', ev.calendar_id
    assert_equal 'CAL001,7', ev.relationships[:label][:id]
    assert_equal 'CAL001,USER001', ev.relationships[:creator][:id]
    attendee_ids = ev.relationships[:attendees].map { |d| d[:id] }
    assert_equal %w[CAL001,USER001], attendee_ids
    if include_option
      creator = ev.creator
      assert_equal 'CAL001,USER001', creator.id
      assert_equal 'user', creator.type
      assert_equal 'USER001 Name', creator.name
      assert_equal 'USER001 Description', creator.description
      assert_equal 'https://attachments.timetreeapp.com/USER001.png', creator.image_url

      label = ev.label
      assert_equal 'CAL001,7', label.id
      assert_equal 'label', label.type
      assert_equal 'French rose', label.name
      assert_equal '#f35f8c', label.color

      attendees = ev.attendees
      assert_equal 1, ev.attendees.length
      att1 = attendees[0]
      assert_equal 'CAL001,USER001', att1.id
      assert_equal 'user', att1.type
      assert_equal 'USER001 Name', att1.name
      assert_equal 'USER001 Description', att1.description
      assert_equal 'https://attachments.timetreeapp.com/USER001.png', att1.image_url
    else
      assert_nil ev.creator
      assert_nil ev.label
      assert_nil ev.attendees
    end
  end

  def assert_ev002(ev, include_option: false, skip_assert_id: false)
    assert_equal 'EV002', ev.id unless skip_assert_id
    assert_equal 'event', ev.type
    assert_equal 'EV002 Title', ev.title
    assert_equal 'schedule', ev.category
    assert_equal true, ev.all_day
    assert_equal Time.parse('2020-06-21T00:00:00.000Z').to_i, ev.start_at.to_i
    assert_equal 'UTC', ev.start_timezone
    assert_equal Time.parse('2020-06-21T00:00:00.000Z').to_i, ev.end_at.to_i
    assert_equal 'UTC', ev.end_timezone
    assert_nil ev.recurrences
    assert_equal 'ABCDE12345', ev.recurring_uuid
    assert_equal 'EV002 Description', ev.description
    assert_equal 'EV002 Location', ev.location
    assert_nil ev.url
    assert_equal Time.parse('2020-06-18T09:00:00.000Z').to_i, ev.updated_at.to_i
    assert_equal Time.parse('2020-06-18T09:00:00.000Z').to_i, ev.created_at.to_i
    assert_equal 'CAL001', ev.calendar_id
    assert_equal 'CAL001,7', ev.relationships[:label][:id]
    assert_equal 'CAL001,USER001', ev.relationships[:creator][:id]
    attendee_ids = ev.relationships[:attendees].map { |d| d[:id] }
    assert_equal %w[CAL001,USER001], attendee_ids
    if include_option
      creator = ev.creator
      assert_equal 'CAL001,USER001', creator.id
      assert_equal 'user', creator.type
      assert_equal 'USER001 Name', creator.name
      assert_equal 'USER001 Description', creator.description
      assert_equal 'https://attachments.timetreeapp.com/USER001.png', creator.image_url

      label = ev.label
      assert_equal 'CAL001,7', label.id
      assert_equal 'label', label.type
      assert_equal 'French rose', label.name
      assert_equal '#f35f8c', label.color

      attendees = ev.attendees
      assert_equal 1, ev.attendees.length
      att1 = attendees[0]
      assert_equal 'CAL001,USER001', att1.id
      assert_equal 'user', att1.type
      assert_equal 'USER001 Name', att1.name
      assert_equal 'USER001 Description', att1.description
      assert_equal 'https://attachments.timetreeapp.com/USER001.png', att1.image_url
    else
      assert_nil ev.creator
      assert_nil ev.label
      assert_nil ev.attendees
    end
  end

  def assert_ev003(ev, include_option: false, skip_assert_id: false)
    assert_equal 'EV003', ev.id unless skip_assert_id
    assert_equal 'event', ev.type
    assert_equal 'EV003 Title', ev.title
    assert_equal 'keep', ev.category
    assert_equal false, ev.all_day
    assert_equal Time.parse('2020-06-22T01:00:00.000Z').to_i, ev.start_at.to_i
    assert_equal 'Asia/Tokyo', ev.start_timezone
    assert_equal Time.parse('2020-06-22T02:00:00.000Z').to_i, ev.end_at.to_i
    assert_equal 'Asia/Tokyo', ev.end_timezone
    assert_nil ev.recurrences
    assert_nil ev.recurring_uuid
    assert_equal 'EV003 Description', ev.description
    assert_equal 'Los Angeles', ev.location
    assert_equal 'https://github.com/', ev.url
    assert_equal Time.parse('2020-06-21T00:07:23.059Z').to_i, ev.updated_at.to_i
    assert_equal Time.parse('2020-06-21T00:07:22.852Z').to_i, ev.created_at.to_i
    assert_equal 'CAL001', ev.calendar_id
    assert_equal 'CAL001,2', ev.relationships[:label][:id]
    assert_equal 'CAL001,USER001', ev.relationships[:creator][:id]
    attendee_ids = ev.relationships[:attendees].map { |d| d[:id] }
    assert_equal %w[CAL001,USER001], attendee_ids
    if include_option
      creator = ev.creator
      assert_equal 'CAL001,USER001', creator.id
      assert_equal 'user', creator.type
      assert_equal 'USER001 Name', creator.name
      assert_equal 'USER001 Description', creator.description
      assert_equal 'https://attachments.timetreeapp.com/USER001.png', creator.image_url

      label = ev.label
      assert_equal 'CAL001,2', label.id
      assert_equal 'label', label.type
      assert_equal 'Modern cyan', label.name
      assert_equal '#3dc2c8', label.color

      attendees = ev.attendees
      assert_equal 1, ev.attendees.length
      att1 = attendees[0]
      assert_equal 'CAL001,USER001', att1.id
      assert_equal 'user', att1.type
      assert_equal 'USER001 Name', att1.name
      assert_equal 'USER001 Description', att1.description
      assert_equal 'https://attachments.timetreeapp.com/USER001.png', att1.image_url
    else
      assert_nil ev.creator
      assert_nil ev.label
      assert_nil ev.attendees
    end
  end

  def assert_activity001(act)
    assert_equal 'ACT001', act.id
    assert_equal 'activity', act.type
    assert_equal 'ACT001 Content', act.content
    assert_equal Time.parse('2020-06-20T11:08:56.510Z').to_i, act.created_at.to_i
    assert_equal Time.parse('2020-06-20T11:08:56.510Z').to_i, act.updated_at.to_i
    assert_equal 'CAL001', act.calendar_id
    assert_equal 'EV001', act.event_id
  end
end
