FROM ruby:2.3.8

# Switch to archive repos and disable GPG checks
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list \
 && sed -i '/security.debian.org/d' /etc/apt/sources.list \
 && sed -i '/stretch-updates/d' /etc/apt/sources.list \
 && apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::AllowInsecureRepositories=true \
 && apt-get install -y --allow-unauthenticated \
        build-essential \
        libmariadb-dev \
        nodejs \
        vim-tiny \
 && rm -rf /var/lib/apt/lists/*

# Install old Bundler that works with Rails 4.2
RUN gem install bundler -v 1.17.3

WORKDIR /app

# Prevent Gemfile.lock errors
COPY Gemfile Gemfile.lock ./
RUN bundle _1.17.3_ install || true

COPY . .
