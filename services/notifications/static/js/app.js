window.onload = function () {

    console.log("Protocol: " + location.protocol);
    var wsURL = location.protocol + "//" + document.location.host
    
    var log = document.getElementById("notifications");

    function appendLog(item) {
        var doScroll = log.scrollTop > log.scrollHeight - log.clientHeight - 1;
        log.appendChild(item);
        if (doScroll) {
            log.scrollTop = log.scrollHeight - log.clientHeight;
        }
    }

    if (log) {
        var hostDiv = document.getElementById("host");
        hostDiv.innerText = document.location.host;

        var sock = io.connect(wsURL);
        var connDiv = document.getElementById("connection-status");
        connDiv.innerText = "closed";

        sock.on('connect', function () {
            console.log("connected to " + wsURL);
            connDiv.innerText = "open";
        });

        sock.on('disconnect', function (e) {
            console.log("connection closed (" + e.code + ")");
            connDiv.innerText = "closed";
        });

        sock.on('message', function (data) {
            var item = document.createElement("div");
            item.className = "item";
            
            // Parse the JSON string from the message property
            var orderData;
            try {
                orderData = JSON.parse(data.message);
            } catch (e) {
                // Fallback if parsing fails
                orderData = { order_id: "unknown", message: data.message || "Error parsing message" };
            }
            
            // Create formatted message
            var timestamp = new Date().toLocaleTimeString();
            var message = "<i>" + timestamp + "</i> | <b>" + 
                          orderData.order_id + "</b> | <i>" + 
                          orderData.message + "</i>";
            
            item.innerHTML = "<div class='item-text'>" + message + "</div>";
            appendLog(item);
        });

    } 
};
