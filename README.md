# Support Table

[![Continuous Integration](https://github.com/bdurand/support_table/actions/workflows/continuous_integration.yml/badge.svg)](https://github.com/bdurand/support_table/actions/workflows/continuous_integration.yml)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](https://github.com/testdouble/standard)

## Usage

This gem builds on top of the [support_table_data](https://github.com/bdurand/support_table_data) and [support_table_cache](https://github.com/bdurand/support_table_cache) gems to provide a simple drop-in solution for maintaining and using support tables in a Rails application.

It helps with the kinds of tables that contain a small number of static rows that rarely if ever change by providing:

* automatic caching of data to eliminate round trips to the database
* a mechanism for populating the static data in the tables
* helper methods to enable referencing specific rows from within code

### Example

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

Now let's define the models with `Status` as a support table.

```ruby
class Status < ApplicationRecord
  include SupportTable
end

class Task < ApplicationRecord
  belongs_to_support_table :status
end
```

Including `SupportTable` in a class will inject the the following behavior in your model:

* Calls to `find_by` using values with unique indexes will be cached.
* Rows will be saved to local memory

You can customize the default behavior with the `support_table` method. This is how the default behavior would be defined:

```ruby
class Status < ApplicationRecord
  include SupportTable
  
  support_table data_file: "statuses.yml",
                key_attribute: :name,
                cache_by: [:id, :name],
                cache: :memory
end
```

Create a YAML file at `db/support_tables/statuses.yml` to define the data that should be in the table.

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

Enhance the `db:migrate` rake task with a Rakefile in `lib/tasks`.

```ruby
if Rake::Task.task_defined?("db:migrate")
  Rake::Task["db:migrate"].enhance do
    Rake::Task["support_table_data:sync"].invoke
  end
end
```

Finally, you'll need to add this line to your test suite setup code.

```ruby
SupportTable.sync_all!
```

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
