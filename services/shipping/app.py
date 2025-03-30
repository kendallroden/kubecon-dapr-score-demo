import logging
import os
from flask import Flask, request, jsonify, make_response

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


APP_PORT = int(os.getenv("APP_PORT", 3004))

app = Flask(__name__)

@app.post('/api/v1/shipments')
def create_shipping_order():
    # Validate input
    if not request.is_json:
        return make_response(
            jsonify({"error": "Bad Request", "message": "Request must be JSON"}),
            400
        )
    
    order_data = request.json

    if not order_data or not isinstance(order_data, dict):
        return make_response(
            jsonify({"error": "Bad Request", "message": "Invalid order format"}),
            400
        )
    
    logging.info(f"Processing shipping order: {order_data}")
    
    # Uncomment for testing
    # import time  
    # time.sleep(1)
    
    return make_response(
        jsonify({"id": order_data['id'], "success": True, "message": "Shipping order created successfully"}),
        201
    )

# Health check endpoint
@app.get('/health')
@app.get('/healthz')
def health_check():
    return jsonify({
        "service": "shipping-service",
        "status": "healthy",
        "version": "1.0.0"  # Consider using dynamic versioning
    })


def main():
    # Start the Flask app server
    app.run(host='0.0.0.0', port=APP_PORT, debug=False)


if __name__ == "__main__":
    logging.basicConfig(
        format='%(asctime)s.%(msecs)03d %(levelname)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S',
        level=logging.INFO)
    
    # Warn if running in debug mode in production
    if APP_PORT != 3004:  # Assuming non-default port means production
        logging.warning("Running with debug=False in production environment")
    
    main()