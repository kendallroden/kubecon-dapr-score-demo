import logging
import os
import time
import json
import random
import uuid

from flask import Flask, request
from models import AmountMoney, CreatePayment, Order

APP_PORT = os.getenv("APP_PORT", "3003")

app = Flask(__name__)


@app.post("/payments/charge")
def charge():

    order_data = request.get_json()

    # Create an Order instance
    order = Order(**order_data)  # Unpack the dictionary to create an instance

    # Randomly choosing a test card, one which fails and one which succeeds
    sourceIds = list({"cnon:card-nonce-ok", "4000000000000002"})

    # Define the amount money object
    cost = AmountMoney(amount=order.total, currency="USD")

    # Generate a unique idempotency key
    idempotency_key = str(uuid.uuid4())

    # Create the instance of CreatePayment
    payment_instance = CreatePayment(
        amount_money=cost,
        idempotency_key=idempotency_key,
        source_id=random.choice(sourceIds),
        autocomplete=True,
        customer_id=order.customer,
        reference_id=(order.customer + str(idempotency_key)),
        note="Payment attempt"
    )

    logging.info(f"Charging payment for order: {order} with payment: {payment_instance}")

    payment_result = {"success": True, "message": "Payment was accepted"}

    return payment_result, 200
                
    


@app.route("/payments/refund", methods=["POST"])
def refund():
    logging.info(f"Refunding payment for order: {request.json}")

    # Simulate work
    time.sleep(1)

    return '', 200


@app.route("/", methods=["GET"])
@app.route("/healthz", methods=["GET"])
def hello():
    return f"Hello from {__name__}", 200


def main():
    # Start the Flask app server
    app.run(host='0.0.0.0', port=APP_PORT, debug=True, use_reloader=False)


if __name__ == "__main__":
    logging.basicConfig(
        format='%(asctime)s.%(msecs)03d %(levelname)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        level=logging.INFO)
    main()
