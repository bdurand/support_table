# frozen_string_literal: true

module SupportTable
  class Railtie < Rails::Railtie
    rake_tasks do
      ["db:migrate", "db:test:prepare", "db:seed"].each do |task_name|
        Rake::Task[task_name].enhance do
          Rake::Task["support_table_data:sync"].invoke
        end
      end
    end
  end
end
