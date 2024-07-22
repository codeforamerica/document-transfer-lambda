# frozen_string_literal: true

require 'faraday'

# Lambda execution handler.
class Handler
  # Expiration time, in seconds, for the presigned URL.
  EXPIRATION_TIME = 300

  # The expected tag key for scan results.
  TAG_KEY = 'scan-result'
  TAG_VALUE = 'clean'

  def initialize(config:, logger:, s3_client:)
    @config = config
    @logger = logger
    @s3 = s3_client
  end

  # Handles an individual execution
  def handle(event:, context:)
    @logger.debug(event)
    record = event['detail']
    @logger.info("Received request (#{context.aws_request_id}) for " \
                 "#{record['bucket']['name']}/#{record['object']['key']}")

    # Make sure the file has been scanned for viruses and is clean.
    scanned?(record['bucket']['name'], record['object']['key'])
    @logger.info('File has been scanned and is clean')
    url, _headers = download_url(record['bucket']['name'], record['object']['key'])

    transfer_client = Faraday.new(@config.url)
    response = transfer_client.post(
      '/transfer',
      transfer_body(url, record['object']['key']),
      {
        'x-correlation-id' => context.aws_request_id,
        'authorization' => "Bearer realm=\"#{@config.credentials['id']}\" #{@config.credentials['token']}"
      }
    )
    @logger.info("Transfer completed with #{response.status}")
    @logger.debug("Transfer response: #{response.body}")

    raise 'Transfer failed' unless response.success?
  end

  private

  def download_url(bucket, key)
    Aws::S3::Presigner.new.presigned_url(
      :get_object,
      bucket:,
      key:,
      expires_in: EXPIRATION_TIME
    )
  end

  def scanned?(bucket, key)
    object_tags = tags(bucket, key)
    @logger.debug("Object has tags: #{object_tags}")

    raise 'File has not been scanned' if object_tags.empty?
    raise 'File has failed virus scan' unless object_tags.any? do |tag|
      tag.key == TAG_KEY && tag.value.downcase == TAG_VALUE
    end

    true
  end

  def tags(bucket, key)
    @s3.get_object_tagging(
      bucket:,
      key:,
    ).tag_set
  end

  def transfer_body(url, filename)
    {
      source: {
        type: :url,
        url:
      },
      destination: {
        type: :onedrive,
        path: @config.folder,
        filename:
      }
    }
  end
end
