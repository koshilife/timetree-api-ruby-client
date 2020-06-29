# frozen_string_literal: true

require 'test_helper'

class TimeTreeEventTest < TimeTreeBaseTest
  def setup
    super
    @ev = fetch_ev001
    @no_client_ev = TimeTree::Event.new(**{
                                          id: 'NO_CLIENT_EV001',
                                          type: 'event'
                                        })
    @no_id_ev = TimeTree::Event.new(**{
                                      type: 'event',
                                      client: @client
                                    })
  end

  def test_model_inspect
    assert_equal "\#<#{@ev.class}:#{@ev.object_id} id:#{@ev.id}>", @ev.inspect
  end

  #
  # test for TimeTree::Event#create
  #

  def test_create
    ev = @ev.dup
    new_title = 'NEW_EV001 Title'
    ev.title = new_title

    res_body = load_test_data('event_001_create.json')
    add_stub_request(:post, "#{HOST}/calendars/CAL001/events", req_body: ev.data_params, res_status: 201, res_body: res_body)
    new_ev = ev.create
    assert_equal 'NEW_EV001', new_ev.id
    assert_ev001 new_ev, skip_assert_id: true, skip_assert_title: true
  end

  def test_create_then_fail
    e =
      assert_raises StandardError do
        @no_client_ev.create
      end
    assert_client_nil_error e
  end

  #
  # test for TimeTree::Event#update
  #

  def test_update
    ev = @ev.dup
    ev.title = 'EV001 Title Updated'
    res_body = load_test_data('event_001_update.json')
    add_stub_request(:put, "#{HOST}/calendars/CAL001/events/EV001", req_body: ev.data_params, res_body: res_body)
    updated_ev = ev.update
    assert_equal ev.title, updated_ev.title
    assert_ev001 updated_ev, skip_assert_title: true
  end

  def test_update_then_fail_because_no_client
    e =
      assert_raises StandardError do
        @no_client_ev.update
      end
    assert_client_nil_error e
  end

  #
  # test for TimeTree::Event#delete
  #

  def test_delete
    add_stub_request(:delete, "#{HOST}/calendars/CAL001/events/EV001", res_status: 204)
    assert @ev.delete
  end

  def test_delete_then_fail_because_no_client
    e =
      assert_raises StandardError do
        @no_client_ev.delete
      end
    assert_client_nil_error e
  end

  #
  # test for TimeTree::Event#create_comment
  #

  def test_create_comment
    message = 'comment1'
    data_params = { data: { attributes: { content: message } } }
    res_body = load_test_data('activity_001_create.json')
    add_stub_request(:post, "#{HOST}/calendars/CAL001/events/EV001/activities", req_body: data_params, res_status: 201, res_body: res_body)

    activity = @ev.create_comment message
    assert_activity001 activity
  end

  def test_create_comment_then_fail_because_no_client
    e =
      assert_raises StandardError do
        @no_client_ev.create_comment 'comment1'
      end
    assert_client_nil_error e
  end

  #
  # test for TimeTree::Event#data_params
  #

  def test_data_params
    expected = {
      data: {
        attributes: {
          category: 'schedule',
          title: 'EV001 Title',
          all_day: false,
          start_at: '2020-06-20T10:00:00Z',
          start_timezone: 'Asia/Tokyo',
          end_at: '2020-06-20T11:00:00Z',
          end_timezone: 'Asia/Tokyo',
          description: nil,
          location: 'EV001 Location',
          url: 'https://github.com'
        },
        relationships: {
          label: { data: { type: 'label', id: 'CAL001,7' } },
          attendees: { data: [{ type: 'user', id: 'CAL001,USER001' }] }
        }
      }
    }
    assert_equal expected, @ev.data_params
  end

  def test_data_params_with_label_and_attendees
    label_params = { type: 'label', id: 'CAL001,4' }
    @ev.label = TimeTree::Label.new(**label_params)
    user_params1 = { type: 'user', id: 'CAL001,USER001' }
    user_params2 = { type: 'user', id: 'CAL001,USER002' }
    @ev.attendees = [user_params1, user_params2].map { |params| TimeTree::User.new(**params) }
    expected = {
      data: {
        attributes: {
          category: 'schedule',
          title: 'EV001 Title',
          all_day: false,
          start_at: '2020-06-20T10:00:00Z',
          start_timezone: 'Asia/Tokyo',
          end_at: '2020-06-20T11:00:00Z',
          end_timezone: 'Asia/Tokyo',
          description: nil,
          location: 'EV001 Location',
          url: 'https://github.com'
        },
        relationships: {
          label: { data: { type: 'label', id: 'CAL001,4' } },
          attendees: { data: [{ type: 'user', id: 'CAL001,USER001' }, { type: 'user', id: 'CAL001,USER002' }] }
        }
      }
    }
    assert_equal expected, @ev.data_params
  end
end
