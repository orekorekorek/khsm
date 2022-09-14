source 'https://rubygems.org'

gem 'rails', '~> 4.2.10'

# Удобная админка для управления любыми сущностями
gem 'rails_admin'

gem 'devise', '~> 4.1.1'
gem 'devise-i18n'

gem 'uglifier', '>= 1.3.0'

gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'russian'
gem 'twitter-bootstrap-rails'

group :development, :test do
  gem 'byebug'
  gem 'factory_girl_rails'
  gem 'rspec-rails', '~> 3.4'
  gem 'shoulda-matchers'
  gem 'sqlite3', '~> 1.3.13'

  # Гем, который использует rspec, чтобы смотреть наш сайт
  gem 'capybara'

  # Гем, который позволяет смотреть, что видит capybara
  gem 'launchy'
end

group :production do
  # гем, улучшающий вывод логов на Heroku
  # https://devcenter.heroku.com/articles/getting-started-with-rails4#heroku-gems
  gem 'pg'
  gem 'rails_12factor'
end
