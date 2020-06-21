# TimeTree Api Client

[![Gem Version](https://badge.fury.io/rb/timetree.svg)](http://badge.fury.io/rb/timetree)

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

The Api client needs access token.
Set `access_token` to the value you got by above:

```ruby
# using configure
TimeTree.configure do |config|
  config.access_token = '<YOUR_ACCESS_TOKEN>'
end
client = TimeTree::Client.new

# using initializer
client = TimeTree::Client.new('<YOUR_ACCESS_TOKEN>')

# TODO
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/koshilife/timetree-api-ruby-client). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TimeTree Api Client project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/koshilife/timetree-api-ruby-client/blob/master/CODE_OF_CONDUCT.md).
