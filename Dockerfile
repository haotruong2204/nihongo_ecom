FROM ruby:3.3.4

RUN apt-get update -qq && \
    apt-get install -y build-essential libssl-dev nodejs libpq-dev less vim nano libsasl2-dev

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt update && apt install yarn

ENV WORK_ROOT /src
ENV APP_HOME $WORK_ROOT/app/
ENV LANG C.UTF-8
ENV GEM_HOME $WORK_ROOT/bundle
ENV BUNDLE_BIN $GEM_HOME/gems/bin
ENV PATH $GEM_HOME/bin:$BUNDLE_BIN:$PATH

RUN gem install bundler -v 2.5.19

RUN mkdir -p $APP_HOME

RUN bundle config --path=$GEM_HOME
RUN bundle config set force_ruby_platform true

WORKDIR $APP_HOME

ADD Gemfile ./
ADD Gemfile.lock ./
RUN bundle update --bundler
RUN bundle install

ADD . $APP_HOME

EXPOSE 3000
