# frozen_string_literal: true

require 'aws-sdk-secretsmanager'

# Retrieve and validate lambda configuration.
class Config
  attr_reader :folder, :log_level, :url

  def initialize(credentials:, folder:, url:, log_level: Logger::INFO)
    @credentials = credentials
    @log_level = log_level
    @folder = folder
    @url = url
    @mutex = Mutex.new

    validate_required
  end

  def self.from_env
    new(
      credentials: ENV.fetch('CREDENTIALS_ARN', nil),
      folder: ENV.fetch('ONEDRIVE_FOLDER', nil),
      log_level: ENV.fetch('LOG_LEVEL', Logger::INFO),
      url: ENV.fetch('TRANSFER_URL', nil)
    )
  end

  def credentials
    secrets[:credentials]
  end

  private

  def validate_required
    raise 'Microservice URL is required.' unless @url
  end

  def secrets
    @mutex.synchronize do
      return @secrets if @secrets

      secrets = Aws::SecretsManager::Client.new.get_secret_value(secret_id: @credentials)
      @secrets = { credentials: JSON.parse(secrets.secret_string) }
    end
  end
end
