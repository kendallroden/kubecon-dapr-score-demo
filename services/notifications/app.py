import logging
import os

# Enable debug mode only when environment variable is set
if os.environ.get('PYTHON_DEBUG', '').lower() == 'true':
    import debugpy
    service_name = os.environ.get('SERVICE_NAME', 'unknown')
    debug_port = int(os.environ.get('DEBUG_PORT', '5678'))
    
    print(f"🔍 [{service_name}] Enabling debugpy on port {debug_port}")
    debugpy.listen(("0.0.0.0", debug_port))
    
    # Only wait for connection if explicitly requested
    if os.environ.get('DEBUG_WAIT', '').lower() == 'true':
        print(f"⏳ [{service_name}] Waiting for debugger attach...")
        debugpy.wait_for_client()
        print(f"✅ [{service_name}] Debugger attached!")
        
from flask import Flask, jsonify, render_template, request
from flask_socketio import SocketIO

APP_PORT = os.getenv("APP_PORT", "3001")
TOPIC_NAME = os.getenv("TOPIC_NAME", "notifications")
WITH_SCORE = os.getenv("WITH_SCORE", "false")
INVENTORY_TYPE = os.getenv("INVENTORY_TYPE", "Redis")
NOTIFICATIONS_TYPE = os.getenv("NOTIFICATIONS_TYPE", "Redis")
RUNTIME = os.getenv("RUNTIME", "")

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

@socketio.on('connect')
def socket_connect():
    print('connected', flush=True)


@app.route('/')
def index():
    return render_template('index.html', with_score=WITH_SCORE, inventory_type=INVENTORY_TYPE, notifications_type=NOTIFICATIONS_TYPE, runtime=RUNTIME)


@app.route('/' + TOPIC_NAME, methods=['POST', 'PUT'])
def topic_notifications():
    # Handles notification events from the Dapr pubsub component.
    logging.info(f"Received notification: {request.json}")
    event = request.json
    # Extract the message string from the input field
    message = event.get('data', '')
    socketio.emit('message', {'message': message})
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
