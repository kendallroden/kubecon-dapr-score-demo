import logging
import os

from flask import Flask, jsonify, render_template, request
from flask_socketio import SocketIO

APP_PORT = os.getenv("APP_PORT", "3001")
TOPIC_NAME = os.getenv("TOPIC_NAME", "notifications")
WITH_SCORE = os.getenv("WITH_SCORE", "false")
INVENTORY_TYPE = os.getenv("INVENTORY_TYPE", "Redis")
NOTIFICATIONS_TYPE = os.getenv("NOTIFICATIONS_TYPE", "Redis")

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")


@socketio.on('connect')
def socket_connect():
    print('connected', flush=True)


@app.route('/')
def index():
    return render_template('index.html', with_score=WITH_SCORE, inventory_type=INVENTORY_TYPE, notifications_type=NOTIFICATIONS_TYPE)


@app.route('/' + TOPIC_NAME, methods=['POST', 'PUT'])
def topic_notifications():
    """Handles notification events from the Dapr pubsub component.
    Ref: https://docs.dapr.io/reference/api/pubsub_api/#provide-routes-for-dapr-to-deliver-topic-events"""
    logging.info(f"Received notification: {request.json}")
    event = request.json
    socketio.emit('message', event)
    return '', 200


@app.route("/healthz", methods=["GET"])
def hello():
    return f"Hello from {__name__}", 200


def main():
    logging.info("Starting Flask app...")
    socketio.run(app, host='0.0.0.0', port=APP_PORT, allow_unsafe_werkzeug=True)


if __name__ == "__main__":
    logging.basicConfig(
        format='%(asctime)s.%(msecs)03d %(levelname)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        level=logging.INFO)
    main()
