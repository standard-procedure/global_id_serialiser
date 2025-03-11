# GlobalIdSerialiser

A [Ruby on Rails serialiser](https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Serialization/ClassMethods.html) that can read and write ActiveRecord models (or any other [GlobalID](https://github.com/rails/globalid)) to your serialised fields.  

## Usage

Create your ActiveRecord model, declaring your serialised field as normal.  But instead of declaring the `coder` as `JSON`, use `GlobalIdSerialiser`.

```ruby
class BlogPost < ApplicationRecord 
  serialize :data, coder: GlobalIdSerialiser, type: Hash
end
```

Then go about your day, safely storing your models in your serialised field. 

```ruby
@alice = Person.create name: "Alice"

@blog_post = BlogPost.create data: { title: "Welcome to my blog", author: @alice }

puts @blog_post.data # => { "title": "Welcome to my blog", "author": "gid://my_app/person/1" }

@reloaded_blog_post = BlogPost.find @blog_post.id 

puts @blog_post.data["author"] # => Person<id: 1, name: "Alice">
```

## Installation

Add it to your Gemfile.  `bundle install`.  Relax.  

## License

This is licensed under the [LGPL](/LICENSE).  This may or may not make it suitable for your needs.  