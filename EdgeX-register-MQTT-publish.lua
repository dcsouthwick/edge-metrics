#!/usr/bin/env lua5.1
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require ("dkjson")

endpoints = {
   metadata = "localhost:48081",
   export_client = "localhost:48071",
   data = "localhost:48080",
   command = "localhost:48082",
   logging = "localhost:48061",
   notifications = "localhost:48060",
}

function post(target, path, data)
   local payload = json.encode(data)
   local response_body = { }
   local url = "http://" .. endpoints[target] .. "/api/v1/" .. path
   local res, code, response_headers, status = http.request
   {
      url = url,
      method = "POST",
      headers = {
         ["Content-Type"] = "application/json",
         ["Content-Length"] = payload:len()
      },
      source = ltn12.source.string(payload),
      sink = ltn12.sink.table(response_body),
   }
   print(url)
   print(payload)
   print(code)

   print("res = " .. res .. " code = " .. code .. " response_headers = " ..
            table.concat(response_headers, ',') .. "status = " .. status ..
            " response_body = " .. table.concat(response_body))
   for k, v in pairs(response_body) do
      print(k, v)
   end
   return code, table.concat(response_body)
end

function register_mqtt_export (exportNameParam, filterParam, topicNameParam)
   id = { name = exportNameParam .. " Address",
	  protocol = "TCP",
	  address = mqtt_addr,
	  port = 1883,
          method = "POST",
	  publisher = exportNameParam,
	  topic = topicNameParam }
   
   post("metadata", "addressable", id)

   post("export_client", "registration", { name = exportNameParam,
					   addressable = id,
					   format = "JSON",
                                           filter = { deviceIdentifiers = { filterParam }},
					   destination = "MQTT_TOPIC",
					   enable = true })
end


mqtt_addr = arg[1]
if mqtt_addr ~= nil
then
  register_mqtt_export ("MQ_DEVICE", "MQ_DEVICE", "edgex")
else
  print("mqtt address not set")
end
