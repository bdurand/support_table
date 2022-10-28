# frozen_string_literal: true

module SupportTable
  class Railtie < Rails::Railtie
    if Rake::Task.task_defined?("db:migrate")
      Rake::Task["db:migrate"].enhance do
        Rake::Task["support_table_data:sync"].invoke
      end
    end
  end
end
