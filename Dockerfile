FROM ruby:3.2

WORKDIR /app

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  nodejs

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["bash"]
