# ActiveRecord::Pull::Alpha

A simple query interface for pulling deeply nested data from records.

## Synopsis

```ruby
  class Survey < ActiveRecord::Base
    has_many :questions
    has_many :replies
  end

  class Question < ActiveRecord::Base
    has_many :answers
  end

  class Answer < ActiveRecord::Base
    belongs_to :reply
    belongs_to :question
  end

  class Replies < ActiveRecord::Base
    belongs_to :survey
  end

  Survey.find(34).pull(:name, questions: [:text, answers: [:created_at]])
  Survey.where('created_at < ?', Date.new(2018, 7, 5)).pull(:name, questions: :text) 
```

## Why?

Modeling [trees](tree) and [ontologies](ontology) are and excercise in relational database design when using a SQL database.
Unfortunalty, when dealing with deeply nested and overlapping data (e.g. medical records, social data)
trees and ontologies won't do. We need to model graphs, a much more sparsely structured data model, but
this leads to very complex table structures and very complex SQL queries.

This pull syntax is inspired by the pull syntax that is used in [Datomic](datomic-pull), a database that is designed to model
graph-like structures. This gem plugs that syntax into ActiveRecord. As a bonus it makes querying trees and ontologies simple too!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-pull-alpha'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-pull-alpha

## See Also

- [Ancestry](https://github.com/stefankroes/ancestry)
- [Graphiti](https://www.graphiti.dev/)
- [Datomic](datomic)
- [GraphQL](https://graphql.org/)
- [Entity Attribute Value Model](eav-model)
- [RDF](rdf)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

[datomic]: https://www.datomic.com/
[datomic-pull]: https://docs.datomic.com/on-prem/pull.html
[eav-model]: https://en.wikipedia.org/wiki/Entity%E2%80%93attribute%E2%80%93value_model
[rdf]: https://en.wikipedia.org/wiki/Resource_Description_Framework
[tree]: https://en.wikipedia.org/wiki/Tree_(data_structure)
[graph]: https://en.wikipedia.org/wiki/Graph_(abstract_data_type)
[ontology]: https://en.wikipedia.org/wiki/Ontology_(information_science)
