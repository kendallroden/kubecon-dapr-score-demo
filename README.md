# Dapr order solution

The end-to-end solution is comprised of five services:

- **order-processor**: Contains the order process workflow definition and all associated activity methods which will be executed as part of the workflow sequence using the Dapr Workflow API.
- **inventory**: Receives direct invocation requests sent by the order-processor using the Invocation API to manage inventory state in Redis or another supported Dapr state store.
- **notifications**: Subscribes to messages published by the order-processor using the Pub/Sub API and subsequently displays those messages through a simple JavaScript user interface.
- **shipping**: Receives direct invocation requests sent by the order-processor using the Invocation API to simulate the scheduling of order shipments.
- **payments**: Receives direct invocation requests sent by the order-processor using the Invocation API to process order payments which are sent to the Square API using a Dapr HTTP output binding.

## App prerequisites

The solution is comprised of python services:

- Install [Python3](https://www.python.org/downloads/)
- Install [Dapr CLI](https://docs.dapr.io/getting-started/install-dapr-cli/) Version 1.15 + and [initialize dapr locally](https://docs.dapr.io/getting-started/install-dapr-selfhost/)

The payment app makes use of an HTTP output binding pointing to Square. Follow the steps below to configure:

### Setting up your HTTP binding component to connect to the Square Developer Sandbox APIs

1. Navigate to the [Square Developer](https://developer.squareup.com/us/en) website and click "Get started"
1. If you don't already have an account, select "Sign up". Otherwise, enter existing credentials.
1. Add a new application and call it `workflow-payment-app` or your own unique identifier.
1. Select "Skip" on the subsequent blades.
1. On the Credentials page, ensure `Sandbox` is selected in the top slider > find `Sandbox Access token` > Click "show" > Copy the Access Token value.
1. Navigate to the file "local-secret.json" and replace the secret value after "Bearer" with the API token retrieved.

Once you have completed the above steps, you are ready to connect to the Square Payment API from your Dapr Workflow!

> NOTE: The application code calls out to the Square Payment API and will randomly select a failing test card or a successful test card to simulate various workflow paths.

## Connect local app using Dapr multi-app run file

```bash
dapr run -f . 
```

## Use the APIs

A `test.rest` file is available at the root of this repository and can be used with the VS Code `Rest Client` extension.
    ![Rest Client](/images/rest-client.png)
