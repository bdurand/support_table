# Support Table

:construction: NOT RELEASED :construction:

[![Continuous Integration](https://github.com/bdurand/support_table/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/support_table/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

This gem builds on top of the [support_table_data](https://github.com/bdurand/support_table_data) and [support_table_cache](https://github.com/bdurand/support_table_cache) gems to provide a simple drop-in solution for maintaining and using support tables in a Rails application. If you have more advanced needs, you can use those gems directly or in combination with this gem.

Support tables are small database tables that contain static data that rarely changes. They are often used to represent enumerations or lookup values in an application and values are often referenced directly from code.

This gem provides a simple DSL for defining your Rails models as support tables. When a model is defined as a support table

- the data for the table can be defined in a YAML file and distributed with the code
- helper methods can be generated to allow code to reference specific rows from the table
- lookups from the table will use caching to avoid querying the database repeatedly for data that rarely changes

## Usage

Start by including the `SupportTable` concern in your `ApplicationRecord` base model.

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include SupportTable
end
```

This will add DSL methods to your models for defining support tables and associations to them.

```ruby
class Status < ApplicationRecord
  support_table
end

class Task < ApplicationRecord
  belongs_to_support_table :status
end
```

### Defining Support Table Data

You can define the data for your support table in the `db/support_tables` directory in a YAML file. The file name should match the model name in plural form. For the `Status` model, the file would be `db/support_tables/statuses.yml`.

> [!NOTE]
> If the model is in a namespace, the directory structure should reflect that (e.g. `Status::Group` data would be defined in the `db/support_tables/status/groups.yml` file).

```yaml
draft:
  id: 1
  name: Draft

pending:
  id: 2
  name: Pending

in_progress:
  id: 3
  name: In Progress

completed:
  id: 4
  name: Completed
```

The keys in the YAML file are named instances of the model. These will dynamically generate helper methods to load the instance and to test if a value is that instance.

```ruby
Status.draft         # returns the Status instance with name "Draft"

task.status.draft?   # returns true if the task's status is "Draft"
```

Data will be automatically synced to the database whenever rake tasks are run that setup the database (i.e. `db:migrate`, `db:test:prepare`, `db:seed`). This ensures that the data is always present in the database and matches the values defined in the codebase. You can also manually trigger synchronization with the `support_table_data:sync` rake task.

> [!TIP]
> Depending on your test environment setup, you may need to add a call to `SupportTable.sync_all!` in your test suite setup code to ensure that the data is present in the test database.

#### Advanced Data Settings

You can customize the behavior of the support table data syncing by passing options to the `support_table` method.

##### Key Attribute

One of the attributes on the table will be used as the unique identifier for each row in the YAML file. By default, this is will be the primary key on the table. You can set a different attribute by passing the `key_attribute` option.

```ruby
class Status < ApplicationRecord
  support_table key_attribute: :name
end
```

> [!TIP]
> If you are starting from scratch, the primary key is the best choice for the key attribute. If all of the data in the table will be specified in the YAML file, you should turn off auto incrementing primary keys with `auto_increment: false` on the `create_table` statement.
>
> If you are adding support table behavior to an existing table, you may need to use an existing unique attribute instead especially if the primary key is not identical in the existing environments.
>
> Make sure that the attribute you choose has a unique index on it to ensure data integrity and that the values will never need to change. Using a display attribute can be problematic if it ever needs to change. It's best to add a new internal identifier attribute if needed (i.e. add a `code` attribute instead of using the `name` attribute if the `name` might ever change).

#### Data File

You can customize the location of the YAML data file by passing the `data_file` option to the `support_table` method.

```ruby
class Status < ApplicationRecord
  support_table data_file: "custom/statuses.yml"
end
```

You can also change the base directory for all support table data files by setting `SupportTable.data_directory` in your application configuration (e.g., in an initializer).

```ruby
# config/initializers/support_table.rb
SupportTable.data_directory = Rails.root.join("db", "support_tables")
```

#### Additional Helper Methods

You can add additional helper methods to your support table models by passing `attribute_helpers` to the `support_table` method.

```ruby
class Status < ApplicationRecord
  support_table attribute_helpers: [:name]
end
```

This will add class methods to the class to reference values directly from the YAML file. You automatically get helper methods for the key attribute defined for the table.

```ruby
Status.draft_name   # returns "Draft"
Status.pending_name # returns "Pending"

Status.draft_id    # returns 1
Status.pending_id  # returns 2
```

These helper methods do not need to hit the database and so can be used in situations where the database is not available (i.e. during application initialization).

> [!TIP]
> You use these methods in lieu of hard coding values in the code or defining constants. This keeps all of the support table data defined in one place (the YAML file) and avoids duplication.

#### More Data Options

See the [support_table_data](https://github.com/bdurand/support_table_data) gem for more details on defining support table data.

You can use any of the DSL methods defined in that gem to further customize how data is loaded.

### Caching

Support table data is often read frequently but changes rarely. To improve performance, lookups from support tables are cached by default.

Caching is automatic and requires no additional setup. Any query that queries a record by the key attribute (i.e. `find_by(id: 1)`) will use the cache. In addition, any column that contains a unique index without a `where` clause will also be cached (i.e. `find_by(name: "Draft")` would be cached if there is a unique index on the `name` column).

You can use the `fetch_by` method to better express in your code that the lookup is using a cache. This method is an alias for `find_by` except that it will raise an error if the lookup is not using a cache.

```ruby
Status.fetch_by(name: "Draft")  # uses the cache or raise an error the model does not support caching by `name`.
```

#### Changing The Cache Implementation

The default caching implementation uses an in memory cache that stores rows in local memory for the lifetime of the application process. This is the most efficient caching strategy for most use cases. If you need a different caching strategy, you can customize it by passing an implementation of `ActiveSupport::Cache::Store` to the `cache` option of the `support_table` method.

```ruby
class Status < ApplicationRecord
  # Use the application cache for caching.
  support_table cache: Rails.cache
end
```

You can also disable caching entirely by passing `cache: false` or `cache: nil`.

```ruby
class Status < ApplicationRecord
  # Disable caching.
  support_table cache: false
end
```

You can specify the value `:memory` to use an in memory cache. This is the default behavior.

```ruby
class Status < ApplicationRecord
  # Use an in memory cache.
  support_table cache: :memory
end
```

#### Specifying Cache Keys

You can also manually specify the attributes that can be used for caching by passing the `cache_by` option to the `support_table` method. This overrides the default behavior of adding all attributes with unique indexes. The primary key and key attribute will always be included in the cache keys, though.

```ruby
class Status < ApplicationRecord
  support_table cache_by: :name # only use id and name for caching and not other unique attributes
end
```

#### Belongs To Caching

When you have another model with a `belongs_to` association to a support table, you can use the `belongs_to_support_table` method to define the association. This will ensure that lookups for the associated support table record will use the cache.

```ruby
class Task < ApplicationRecord
  belongs_to_support_table :status
end
```

This method works exactly like the standard `belongs_to` method except that it ensures that lookups for the associated support table record will use the cache.

#### More Cache Options

See the [support_table_cache](https://github.com/bdurand/support_table_cache) gem for more details on caching support table data.

You can use any of the DSL methods defined in that gem to further customize how models are cached.

### Full Example

For this example, we'll start with a simple application for managing a list of tasks. Each task will have a status.

First, let's start with the table definitions.

```ruby
create_table :statuses do |t|
  t.string :name, null: false, index: {unique: true}
  t.timestamps
end

create_table :tasks do |t|
  t.integer :status_id, null: false, index: true
  t.string :description, null: false
  t.timestamps
end
```

First, you need to include the `SupportTable` concern in your `ApplicationRecord` so that all models have access to it.

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  include SupportTable
end
```

This will add DSL methods to your models for defining support tables and associations to them.

```ruby
class Status < ApplicationRecord
  support_table
end

class Task < ApplicationRecord
  belongs_to_support_table :status
end
```

Next add the YAML file at `db/support_tables/statuses.yml` to define the data that should be in the `statuses` table.

```yaml
draft:
  id: 1
  name: Draft

pending:
  id: 2
  name: Pending

in_progress:
  id: 3
  name: In Progress

finished:
  id: 4
  name: Finished
```

That's it. Now the `Status` will load data from a YAML file and cache lookups automatically including from the `Task#status` association.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "support_table"
```

Then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install support_table
```

## Contributing

Open a pull request on [GitHub](https://github.com/bdurand/support_table).

Please use the [standardrb](https://github.com/testdouble/standard) syntax and lint your code with `standardrb --fix` before submitting.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
