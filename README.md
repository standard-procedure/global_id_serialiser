# GlobalIdSerialiser

A [Ruby on Rails serialiser](https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Serialization/ClassMethods.html) that can read and write ActiveRecord models (or any other [GlobalID](https://github.com/rails/globalid)) to your serialised fields.  

## Usage

### Outside of Rails serialisation

Rails serialisation uses the `GlobalIdSerialiser#dump` and `GlobalIdSerialiser#load` methods - which convert your data to and from JSON.  

However, internally, these methods use `GlobalIdSerialiser#marshal` and `GlobalIdSerialiser#unmarshal`.  These do the conversion from GlobalID to model and back again, without the conversion to JSON.  So you can use these anywhere that expects standard ruby objects.  

```ruby
@alice = Person.create name: "Alice"
@data = { title: "Welcome to my blog", author: @alice }

@marshalled_data = GlobalIdSerialiser.marshal @data 
puts @marshalled_data # => { title: "Welcome to my blog", author: "gid://my_app/person/1" }

@unmarshalled_data = GlobalIdSerialiser.unmarshal @marshalled_data 
puts @unmarshalled_data # => { title: "Welcome to my blog", author: Person<id: 1, name: "Alice"> }
```

### Serialising data to and from ActiveRecord

Create your ActiveRecord model, declaring your serialised field - but instead of declaring the `coder` as `JSON`, use `GlobalIdSerialiser`.

```ruby
class BlogPost < ApplicationRecord 
  serialize :data, coder: GlobalIdSerialiser, type: Hash
end
```

Then go about your day, safely storing your models in your serialised field. 

```ruby
@alice = Person.create name: "Alice"

@blog_post = BlogPost.create data: { title: "Welcome to my blog", author: @alice }

puts @blog_post.data_before_type_cast # => '{"title":"Welcome to my blog","author":"gid://my_app/person/1"}'

@reloaded_blog_post = BlogPost.find @blog_post.id 

puts @blog_post.data["author"] # => Person<id: 1, name: "Alice">
```

### Deleted records

When your data is marshalled, any objects that implement `GlobalID::Identification` get converted to a GlobalID URI string.  

Later, when that data is unmarshalled, any GlobalID URIs are passed to the `GlobalID::Locator` to find them in the database.  If the record in question has been deleted, the data will be unmarshalled as `nil`.  This is so as much of the data as possible is retrieved without raising any `ActiveRecord::RecordNotFound` errors (which would stop the unmarshalling process part-way through and leave you with no data at all).  

So be aware that `nil`s may be returned if the record in question has been deleted.  

## Installation

Add it to your Gemfile.  `bundle install`.  Relax.  

## License

This is licensed under the [LGPL](/LICENSE).  This may or may not make it suitable for your needs.  