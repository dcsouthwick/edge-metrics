// mock MQTT virtual device, used with permission from docs.edgexfoundry.org

function getRandomFloat(min, max) {
    return Math.random() * (max - min) + min;
}

const deviceName = "MQ_DEVICE";
let message = "test-message";

// 1. Publish random number every 10 seconds
schedule('*/10 * * * * *', ()=>{
    var randNum = getRandomFloat(25,29).toFixed(1);
    let body = {
        "metrics": {
            "name": deviceName,
            "cmd": "randnum",
            "randnum": randNum,
            "creation" : Date.now()
        },
        "name": deviceName,
        "cmd": "randnum",
        "randnum": randNum,
        "creation" : Date.now()
    };
    publish( 'sink/kura/W1/DataTopic', JSON.stringify(body));
});

// 2. Receive the reading request, then return the response
// 3. Receive the put request, then change the device value
subscribe( "CommandTopic" , (topic, val) => {
    var data = val;
        if (data.method == "set") {
        message = data[data.cmd]
    }else{
        switch(data.cmd) {
            case "ping":
              data.ping = "pong";
              break;
            case "message":
              data.message = message;
              break;
            case "randnum":
                data.randnum = 12.123;
                break;
          }
    }
    publish( "ResponseTopic", JSON.stringify(data));
});
