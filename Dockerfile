FROM ruby:2.7
RUN apt-get update -qq
RUN gem install bundler
WORKDIR /app
COPY . /app
RUN bundle install

