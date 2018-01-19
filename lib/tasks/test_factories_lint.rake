# frozen_string_literal: true

namespace :test do
  namespace :factories do
    desc 'Lint the factories'
    task lint: :environment do
      puts 'Linting factories...'
      FactoryBot.lint
      puts 'Done'
    end
  end
end
