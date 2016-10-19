## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ucsc_ext_courses'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ucsc_ext_courses

# Usage


## Main function

Most of the functions are written in `lib/ucsc_ext_courses/exec.rb`

The file `lib/ucsc_ext_courses/exec.rb` is self-documented with comments.


## Fetch data with command example

    curl 'http://course.ucsc-extension.edu/modules/shop/searchOfferings.action'  --data '&CatalogID=80&startPosition=0&pageSize=100' --compressed

    http://course.ucsc-extension.edu/modules/shop/index.html?action=section&OfferingID=5270292&SectionID=5278388
