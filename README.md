# Simple TimeTree APIs client

[![Test](https://github.com/koshilife/timetree-api-ruby-client/workflows/Test/badge.svg)](https://github.com/koshilife/timetree-api-ruby-client/actions?query=workflow%3ATest)
[![codecov](https://codecov.io/gh/koshilife/tanita-api-ruby-client/branch/master/graph/badge.svg)](https://codecov.io/gh/koshilife/tanita-api-ruby-client)
[![Gem Version](https://badge.fury.io/rb/timetree.svg)](http://badge.fury.io/rb/timetree)
[![license](https://img.shields.io/github/license/koshilife/timetree-api-ruby-client)](https://github.com/koshilife/timetree-api-ruby-client/blob/master/LICENSE.txt)

## About

These client libraries are created for [TimeTree APIs](https://developers.timetreeapp.com/en).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'timetree'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install timetree

## Usage

The APIs client needs access token.
Set a `token` variable to the value you got by above:

```ruby
# set token by TimeTree.configure methods.
TimeTree.configure do |config|
  config.token = '<YOUR_ACCESS_TOKEN>'
end
client = TimeTree::Client.new

# set token by TimeTree::Client initializer.
client = TimeTree::Client.new('<YOUR_ACCESS_TOKEN>')

# get a current user's information.
user = client.current_user
=> #<TimeTree::User id:xxx_u001>
user.name
=> "USER Name"

# get current user's calendars.
cals = client.calendars
=> [#<TimeTree::Calendar id:xxx_cal001>, #<TimeTree::Calendar id:xxx_cal002>, ...]
cal = cals.first
cal.name
=> "Calendar Name"

# get upcoming events on the calendar.
evs = cal.upcoming_events
=> [#<TimeTree::Event id:xxx_ev001>, #<TimeTree::Event id:xxx_ev002>, ...]
ev = evs.first
ev.title
=> "Event Title"

# updates an event.
ev.title += ' Updated'
ev.start_at = Time.parse('2020-06-20 09:00 +09:00')
ev.end_at = Time.parse('2020-06-20 10:00 +09:00')
ev.update
=> #<TimeTree::Event id:xxx_ev001>

# creates an event.
copy_ev = ev.dup
new_ev = copy_ev.create
=> #<TimeTree::Event id:xxx_new_ev001>

# deletes an event.
ev.delete
=> true

# creates a comment to an event.
ev.create_comment 'Hi there!'
=> #<TimeTree::Activity id:xxx_act001>

# handles APIs error.
begin
  ev.delete
  ev.delete # 404 Error occured.
rescue TimeTree::ApiError => e
  e
  => #<TimeTree::ApiError title:Not Found, status:404>
  e.response
  => #<Faraday::Response>
end

# if the log level set :debug, you can get the request/response information.
TimeTree.configuration.logger.level = :debug
=> #<TimeTree::Event id:event_id_001_not_found>
>> client.event 'cal_id_001', 'event_id_001_not_found'
I, [2020-06-24T10:05:07.294807]  INFO -- : GET https://timetreeapis.com/calendars/cal_id_001/events/event_id_001_not_found?include=creator%2Clabel%2Cattendees
D, [2020-06-24T10:05:07.562038] DEBUG -- : Response status:404, body:{:type=>"https://developers.timetreeapp.com/en/docs/api#client-failure", :title=>"Not Found", :status=>404, :errors=>"Event not found"}
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/koshilife/timetree-api-ruby-client). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TimeTree Api Client project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/koshilife/timetree-api-ruby-client/blob/master/CODE_OF_CONDUCT.md).
