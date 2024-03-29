# Zendesk API Client

## API version support

This client **only** supports Zendesk's v2 API.  Please see our [API documentation](http://developer.zendesk.com) for more information.

## Installation

Currently

    gem install zendesk

will not install this version of the API client. To install this client, either clone this repository and run

    rake install

or add it to a Gemfile like so:

    gem "zendesk", :git => "git://github.com/zendesk/zendesk_api_client_rb.git" #, :tag => "vX.X.X"

## Configuration

Configuration is done through a block returning an instance of Zendesk::Client.
The block is mandatory and if not passed, a Zendesk::ConfigurationException will be thrown.

```
Zendesk.configure do |config|
  # Mandatory:

  # Must be https URL unless it is localhost or 127.0.0.1
  config.url = "https://mydesk.zendesk.com/api/v2"

  config.username = "test.user"
  config.password = "test.password"

  # Optional:

  # Retry uses middleware to notify the user
  # when hitting the rate limit, sleep automatically,
  # then retry the request.
  config.retry = true
  # Logger prints to STDOUT by default
  config.logger = true
  # Logger prints out requests to STDERR
  require 'logger'
  config.logger = Logger.new(STDERR)
  # Changes Faraday adapter
  config.adapter = :patron

  # Merged with the default client options hash
  config.client_options = { :ssl => false }

  # When getting the error 'hostname does not match the server certificate' 
  # use the API at https://yoursubdomain.zendesk.com/api/v2
end
```

Note: This Zendesk API client only supports basic authentication at the moment.

## Usage

The result of configuration is an instance of Zendesk::Client which can then be used in two different methods.

One way to use the client is to pass it in as an argument to individual classes.

```
Zendesk::Ticket.new(client, :id => 1, :priority => "urgent") # doesn't actually send a request, must explicitly call #save
Zendesk::Ticket.create(client, :subject => "Test Ticket", :description => "This is a test", :submitter_id => client.me.id, :priority => "urgent")
Zendesk::Ticket.find(client, :id => 1)
Zendesk::Ticket.delete(client, :id => 1)
```

Another way is to use the instance methods under client.

```
client.tickets.first
client.tickets.find(:id => 1)
client.tickets.create(:subject => "Test Ticket", :description => "This is a test", :submitter_id => client.me.id, :priority => "urgent")
client.tickets.delete(:id => 1)
```

The methods under Zendesk::Client (such as .tickets) return an instance of Zendesk::Collection a lazy-loaded list of that resource.
Actual requests may not be sent until an explicit Zendesk::Collection#fetch, Zendesk::Collection#to_a, or an applicable methods such
as #each.

### Pagination

Zendesk::Collections can be paginated:

```
tickets = client.tickets.page(2).per_page(3)
next_page = tickets.next
previous_page = tickets.prev
```

### Callbacks

Callbacks can be added to the Zendesk::Client instance and will be called (with the response env) after all response middleware.

```
client.insert_callback do |env|
  if env[:status] == 404
    puts "Invalid request"
  end
end
```

### Resource management

Individual resources can be created, modified, saved, and destroyed.

```
ticket = client.tickets[0] # Zendesk::Ticket.find(client, :id => 1)
ticket.priority = "urgent"
ticket.attributes # => { "priority" => "urgent" }
ticket.save # Will PUT => true
ticket.destroy # => true

Zendesk::Ticket.new(client, { :priority => "urgent" })
ticket.new_record? # => true
ticket.save # Will POST
```

### Special case: playlists

Views can be played using different syntax than normal resources.
Playlists are started with:

```
client.play(id)
client.play('incoming')
```

OR

```
Zendesk::Playlist.new(client, id)
```

Playlists are automatically started server-side when created and can then be played using the
Zendesk::Playlist#next method. Also available is the Zendesk::Playlist#each method which
takes a block and will successively get and yield each ticket until the end of the playlist.

```
playlist.each do |ticket|
  ticket.status = "solved"
  ticket.save
end
```

### Special case: Custom resources paths

API endpoints such as tickets/recent or topics/show_many can be accessed through chaining.
They will too return an instance of Zendesk::Collection.

```
client.tickets.recent
client.topics.show_many(:verb => :post, :ids => [1, 2, 3])
```

### Special Case: Current user

Use either of the following to obtain the current user instance:

```
client.users.find(:id => 'me')
client.me
```

### Attaching files

Files can be attached to tickets using either a path or the File class and will
be automatically uploaded and attached.

```
ticket = Ticket.new(...)
ticket.uploads << "img.jpg"
ticket.uploads << File.new("img.jpg")
ticket.save
```

## TODO

* Search class detection
* Nested association saving
* Testing

## Note on Patches/Pull Requests
1. Fork the project.
2. Make your feature addition or bug fix.
3. Add tests for it. This is important so I don't break it in a future version
   unintentionally.
4. Commit, do not mess with rakefile, version, or history. (if you want to have
   your own version, that is fine but bump version in a commit by itself I can
   ignore when I pull)
5. Send me a pull request. Bonus points for topic branches.

## Supported Ruby Versions

Tested with Ruby 1.8.7 and 1.9.3
[![Build Status](https://secure.travis-ci.org/zendesk/zendesk_api_client_rb.png)](http://travis-ci.org/zendesk/zendesk_api_client_rb)

## Copyright

See [LICENSE](https://github.com/zendesk/zendesk_api_client_rb/blob/master/LICENSE)
