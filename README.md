# Api::Gears::Rails
api-gears-rails allows installation of an API client into rails models, to keep data synchronized between a rails model and an API.

## Usage
```ruby
class User < ApplicationRecord
sync_with :BreezeApi, keys: :breeze_id # The first argument is the ApiGears class you've created for the API, located in app/lib. The keys argument tells
                                       # the model which attribute to send to the API when querying for user data.

sync_attr :breeze_id, as: :person_id   # Sets up a mapping between the model attribute "breeze_id" and the API parameter "person_id"
sync_attr :last_name                   # Sets up a mapping between the model attribute "last_name" and the API parameter "last_name"
sync_attr :first_name                  # Sets up a mapping between the model attribute "first_name" and the API parameter "first_name"
sync_attr :email                       # Sets up a mapping between the model attribute "email" and the API parameter "email"
pull_endpoint :person                  # specifies which API endpoint is used to pull data
pull_every 10.minutes                  # limits refresh rate to 10 minutes.

after_api_pull do |data, user|         # callback to run after data is pulled from the server.
                                       # Each verb (defaults :pull, :push,:create,:read,:update,:destroy) has before and after callbacks
                                       # available. For this api in particular, "email address" is nested deeply in the data structure
                                       # so we use a callback as an opportunity to make it more accessible.
    data["email"] = data["details"]["1091623166"][0]["address"]
    user.breeze_data = data            # saving the data in a database column can aid with debugging
    user.save
    user.breeze_data                   # Notice that we must return the data at the end of the proc so that it can be used to sync
end                                    # the attributes we've mapped
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'api-gears-rails'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install api-gears-rails
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
