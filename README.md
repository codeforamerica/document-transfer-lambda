# Document Transfer Lambda

This Lambda function is used to transfer documents uploaded to S3 to another
location, through the [Document Transfer Service][dts]. It uses [EventBridge] to
trigger the Lambda function when a new document is uploaded to the S3 bucket.

### Configuration

The lambda function accepts the following environment variables:

| Name              | Description                                                           | Default  | Required |
|-------------------|-----------------------------------------------------------------------|----------|----------|
| `CREDENTIALS_ARN` | The ARN of the secret containing service credentials.                 | n/a      | yes      |
| `TRANSFER_URL`    | The URL of the Document Transfer Service.                             |          | yes      |
| `LOG_LEVEL`       | The log level for the lambda function.                                | `"info"` | no       |
| `ONEDRIVE_FOLDER` | Name of the folder in OneDrive that documents will be transferred to. | `nil`    | no       |

The secret containing the service credentials should be a JSON object with the
following keys:

```json
{
  "id": "cosumer-id",
  "token": "auth-token"
}
```

## Deployment

The lambda function is managed using AWS' [Serverless Application Model][sam].
Before you begin, you will need to install the [SAM CLI][sam-cli]. Make sure you
are logged into your AWS account and have the appropriate `AWS_PROFILE` set.

To ease configuration, a `sample.env` file is provided with necessary
environment variables. Copy this is `.env` and fill in the necessary values. The
`.env` file is ignored by git, so it will not be committed to the repository.
Unless you have a shell extension that automatically loads the `.env` file,
you will need to source it by running `source .env`.

To deploy to staging, run the following:

```bash
sam deploy --config-file samconfig.yaml --config-env staging
```

For production:

```bash
sam deploy --config-file samconfig.yaml --config-env prood
```

### Configuration

Deployment configuration is managed in two places:

1. `template.yaml`: This is the [SAM template][sam-template] that defines the
   lambda function, permissions, event trigger, and any other resources needed
   to execute the function.
2. `samconfig.yaml`: This is the [SAM CLI configuration file][sam-config] that
   contains the environment-specific configuration options for the deployment.
   This includes the bucket name(s), service URL, networking configuration, etc.

   _Note: We use the YAML format for the configuration rather than the default
   TOML for consistency with our other configuration files._

[dts]: https://github.com/codeforamerica/document-transfer-service
[eventbridge]: https://docs.aws.amazon.com/eventbridge/
[sam]: https://aws.amazon.com/serverless/sam/
[sam-cli]: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/using-sam-cli.html
[sam-config]: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-config.html
[sam-template]: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-specification-template-anatomy.html
