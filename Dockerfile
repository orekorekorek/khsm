FROM ruby:2.3-slim
WORKDIR /code
RUN apt update -qq && \
    apt install --no-install-recommends -yqq  \
      nodejs \
      git
COPY Gemfile ./
RUN apt install --no-install-recommends -yqq libpq-dev sqlite3 libsqlite3-dev
RUN apt-get install build-essential patch zlib1g-dev liblzma-dev -y
RUN apt install libxml2 -y
RUN export NOKOGIRI_USE_SYSTEM_LIBRARIES=true
RUN bundle install
