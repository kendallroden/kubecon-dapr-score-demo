# Dapr order solution

```mermaid
flowchart TD
    inventory-->state-store([StateStore])
    notifications-->subscription([Subscription])-->pubsub([PubSub])
    order-processor-->state-store
    order-processor-->pubsub
    order-processor-->inventory
    order-processor-->payments
    order-processor-->shipping
```

The end-to-end solution is comprised of five services:

- **order-processor**: Contains the order process workflow definition and all associated activity methods which will be executed as part of the workflow sequence using the Dapr Workflow API.
- **inventory**: Receives direct invocation requests sent by the order-processor using the Invocation API to manage inventory state in Redis or another supported Dapr state store.
- **notifications**: Subscribes to messages published by the order-processor using the Pub/Sub API and subsequently displays those messages through a simple JavaScript user interface.
- **shipping**: Receives direct invocation requests sent by the order-processor using the Invocation API to simulate the scheduling of order shipments.
- **payments**: Receives direct invocation requests sent by the order-processor using the Invocation API to process order payments.

## App prerequisites

The solution is comprised of python services:

- Install [Python3](https://www.python.org/downloads/)
- Install [Dapr CLI](https://docs.dapr.io/getting-started/install-dapr-cli/) Version 1.15 + and [initialize dapr locally](https://docs.dapr.io/getting-started/install-dapr-selfhost/)

## Connect local app using Dapr multi-app run file

```bash
dapr run -f . 
```

## Use the APIs

A `test.rest` file is available at the root of this repository and can be used with the VS Code `Rest Client` extension.
