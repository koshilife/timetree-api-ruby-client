# frozen_string_literal: true

module AssertHelper
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

  def assert_ev001(ev, include_option: false, skip_assert_id: false, skip_assert_title: false, skip_assert_calendar_id: false)
    assert_equal 'EV001', ev.id unless skip_assert_id
    assert_equal 'event', ev.type
    assert_equal 'EV001 Title', ev.title unless skip_assert_title
    assert_equal 'schedule', ev.category
    assert_equal false, ev.all_day
    assert_equal Time.parse('2020-06-20T10:00:00.000Z').to_i, ev.start_at.to_i
    assert_equal 'Asia/Tokyo', ev.start_timezone
    assert_equal Time.parse('2020-06-20T11:00:00.000Z').to_i, ev.end_at.to_i
    assert_equal 'Asia/Tokyo', ev.end_timezone
    assert_nil ev.recurrence
    assert_nil ev.recurring_uuid
    assert_nil ev.description
    assert_equal 'EV001 Location', ev.location
    assert_equal 'https://github.com', ev.url
    assert_equal Time.parse('2020-06-18T09:00:00.000Z').to_i, ev.updated_at.to_i
    assert_equal Time.parse('2020-06-18T09:00:00.000Z').to_i, ev.created_at.to_i
    assert_equal 'CAL001', ev.calendar_id unless skip_assert_calendar_id
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

  def assert_ev002(ev, include_option: false, skip_assert_id: false, skip_assert_calendar_id: false)
    assert_equal 'EV002', ev.id unless skip_assert_id
    assert_equal 'event', ev.type
    assert_equal 'EV002 Title', ev.title
    assert_equal 'schedule', ev.category
    assert_equal true, ev.all_day
    assert_equal Time.parse('2020-06-21T00:00:00.000Z').to_i, ev.start_at.to_i
    assert_equal 'UTC', ev.start_timezone
    assert_equal Time.parse('2020-06-21T00:00:00.000Z').to_i, ev.end_at.to_i
    assert_equal 'UTC', ev.end_timezone
    assert_nil ev.recurrence
    assert_equal 'ABCDE12345', ev.recurring_uuid
    assert_equal 'EV002 Description', ev.description
    assert_equal 'EV002 Location', ev.location
    assert_nil ev.url
    assert_equal Time.parse('2020-06-18T09:00:00.000Z').to_i, ev.updated_at.to_i
    assert_equal Time.parse('2020-06-18T09:00:00.000Z').to_i, ev.created_at.to_i
    assert_equal 'CAL001', ev.calendar_id unless skip_assert_calendar_id
    assert_equal 'CAL001,7', ev.relationships[:label][:id]
    assert_equal 'CAL001,APP001', ev.relationships[:creator][:id]
    attendee_ids = ev.relationships[:attendees].map { |d| d[:id] }
    assert_equal %w[CAL001,USER001], attendee_ids
    if include_option
      creator = ev.creator
      assert_equal 'CAL001,APP001', creator.id
      assert_equal 'application', creator.type
      assert_equal 'APPLICATION001 Name', creator.name
      assert_equal 'APPLICATION001 Description', creator.description
      assert_equal 'https://attachments.timetreeapp.com/APP001.png', creator.image_url

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

  def assert_ev003(ev, include_option: false, skip_assert_id: false, skip_assert_calendar_id: false)
    assert_equal 'EV003', ev.id unless skip_assert_id
    assert_equal 'event', ev.type
    assert_equal 'EV003 Title', ev.title
    assert_equal 'keep', ev.category
    assert_equal false, ev.all_day
    assert_equal Time.parse('2020-06-22T01:00:00.000Z').to_i, ev.start_at.to_i
    assert_equal 'Asia/Tokyo', ev.start_timezone
    assert_equal Time.parse('2020-06-22T02:00:00.000Z').to_i, ev.end_at.to_i
    assert_equal 'Asia/Tokyo', ev.end_timezone
    assert_nil ev.recurrence
    assert_nil ev.recurring_uuid
    assert_equal 'EV003 Description', ev.description
    assert_equal 'Los Angeles', ev.location
    assert_equal 'https://github.com/', ev.url
    assert_equal Time.parse('2020-06-21T00:07:23.059Z').to_i, ev.updated_at.to_i
    assert_equal Time.parse('2020-06-21T00:07:22.852Z').to_i, ev.created_at.to_i
    assert_equal 'CAL001', ev.calendar_id unless skip_assert_calendar_id
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

  def assert_ev004_child(ev, skip_assert_calendar_id: false)
    assert_equal 'EV004_CHILD', ev.id
    assert_equal 'event', ev.type
    assert_equal 'EV004_CHILD Title Recurrence', ev.title
    assert_equal 'schedule', ev.category
    assert_equal false, ev.all_day
    assert_equal Time.parse('2020-06-24T03:00:00.000Z').to_i, ev.start_at.to_i
    assert_equal 'Asia/Tokyo', ev.start_timezone
    assert_equal Time.parse('2020-06-24T03:30:00.000Z').to_i, ev.end_at.to_i
    assert_equal 'Asia/Tokyo', ev.end_timezone
    assert_nil ev.recurrence
    assert_equal 'EV004_PARENT', ev.recurring_uuid
    assert_nil ev.description
    assert_equal '', ev.location
    assert_nil ev.url
    assert_equal Time.parse('2020-06-24T01:33:16.564Z').to_i, ev.updated_at.to_i
    assert_equal Time.parse('2020-06-24T01:33:16.555Z').to_i, ev.created_at.to_i
    assert_equal 'CAL001', ev.calendar_id unless skip_assert_calendar_id
    assert_equal 'CAL001,2', ev.relationships[:label][:id]
    assert_equal 'CAL001,USER001', ev.relationships[:creator][:id]
    attendee_ids = ev.relationships[:attendees].map { |d| d[:id] }
    assert_equal %w[CAL001,USER001], attendee_ids
    assert_nil ev.creator
    assert_nil ev.label
    assert_nil ev.attendees
  end

  def assert_ev004_parent(ev, skip_assert_calendar_id: false)
    assert_equal 'EV004_PARENT', ev.id
    assert_equal 'event', ev.type
    assert_equal 'EV004_PARENT Title Recurrence', ev.title
    assert_equal 'schedule', ev.category
    assert_equal false, ev.all_day
    assert_equal Time.parse('2020-06-17T03:00:00.000Z').to_i, ev.start_at.to_i
    assert_equal 'Asia/Tokyo', ev.start_timezone
    assert_equal Time.parse('2020-06-17T03:30:00.000Z').to_i, ev.end_at.to_i
    assert_equal 'Asia/Tokyo', ev.end_timezone
    assert_equal ['RRULE:FREQ=DAILY', 'EXDATE:20200624T030000Z'], ev.recurrence
    assert_nil ev.recurring_uuid
    assert_nil ev.description
    assert_equal '', ev.location
    assert_nil ev.url
    assert_equal Time.parse('2020-06-24T01:33:16.507Z').to_i, ev.updated_at.to_i
    assert_equal Time.parse('2020-06-16T00:13:00.860Z').to_i, ev.created_at.to_i
    assert_equal 'CAL001', ev.calendar_id unless skip_assert_calendar_id
    assert_equal 'CAL001,2', ev.relationships[:label][:id]
    assert_equal 'CAL001,USER001', ev.relationships[:creator][:id]
    attendee_ids = ev.relationships[:attendees].map { |d| d[:id] }
    assert_equal %w[CAL001,USER001], attendee_ids
    assert_nil ev.creator
    assert_nil ev.label
    assert_nil ev.attendees
  end

  def assert_activity001(act, skip_assert_calendar_id: false)
    assert_equal 'ACT001', act.id
    assert_equal 'activity', act.type
    assert_equal 'ACT001 Content', act.content
    assert_equal Time.parse('2020-06-20T11:08:56.510Z').to_i, act.created_at.to_i
    assert_equal Time.parse('2020-06-20T11:08:56.510Z').to_i, act.updated_at.to_i
    assert_equal 'CAL001', act.calendar_id unless skip_assert_calendar_id
    assert_equal 'EV001', act.event_id
  end

  def assert_401_error(err)
    assert_equal TimeTree::ApiError, err.class
    assert_equal 'https://developers.timetreeapp.com/en/docs/api#authentication', err.type
    assert_equal 'Unauthorized', err.title
    assert_equal 401, err.status
    assert_equal "\#<#{err.class}:#{err.object_id} title:#{err.title}, status:#{err.status}>", err.inspect
  end

  def assert_404_calendar_error(err)
    assert_equal TimeTree::ApiError, err.class
    assert_equal 'https://developers.timetreeapp.com/en/docs/api#get-calendarscalendar_id', err.type
    assert_equal 'Not Found', err.title
    assert_equal 404, err.status
  end

  def assert_404_event_error(err)
    assert_equal TimeTree::ApiError, err.class
    assert_equal 'https://developers.timetreeapp.com/en/docs/api#client-failure', err.type
    assert_equal 'Not Found', err.title
    assert_equal 404, err.status
    assert_equal 'Event not found', err.errors
  end

  def assert_client_nil_error(e)
    assert_equal TimeTree::Error, e.class
    assert_equal '@client is nil.', e.message
  end

  def assert_blank_error(e, name)
    assert_equal TimeTree::Error, e.class
    assert_equal "#{name} is required.", e.message
  end
end
