# frozen_string_literal: true

load "#{__dir__}/../vendor/bundle/bundler/setup.rb"

require 'aws-sdk-s3'
require 'logger'
require "#{__dir__}/../lib/config"
require "#{__dir__}/../lib/handler"

config = Config.from_env
$handler = Handler.new(
  config:,
  logger: Logger.new($stdout, level: config.log_level),
  s3_client: Aws::S3::Client.new
)

def lambda_handler(event:, context:)
  $handler.handle(event: event, context: context)
end
