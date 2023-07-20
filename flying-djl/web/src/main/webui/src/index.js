const evtSource = new EventSource("djl-object-detect-web/event/objectDetectionStream");

evtSource.onmessage = (e) => {

  var rawMessage = `${e.data}`;
  
  const jsonMessage = JSON.parse(rawMessage);
  const imageBinaryBytes = jsonMessage.base64DetectedImage;
  
  var dResult = delete jsonMessage['base64DetectedImage'];
  console.log("# of keys in json: "+Object.keys(jsonMessage).length);

  document.getElementById("payload_metadata").innerHTML = "<pre>"+JSON.stringify(jsonMessage, null, 2)+"<pre>";
  document.getElementById("payload_image").src = "data:image/png;base64," + imageBinaryBytes;
};
