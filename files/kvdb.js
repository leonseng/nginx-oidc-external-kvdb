export default { write, read };

function base64Encode(value) {
  return Buffer.from(value).toString('base64');
}

function base64Decode(value) {
  return Buffer.from(value, 'base64').toString();
}

/*
  ETCD functions
*/
function buildEtcdMessageBody(key, value) {
  var req_body = '{"key": "' + base64Encode(key) + '"';
  if (value) {
    req_body += ', "value": "' + base64Encode(value) + '"';
  }
  req_body += '}';

  return req_body;
}

async function write(r, key, value) {
  var req_body = buildEtcdMessageBody(key, value);
  r.log("ETCD write request body: " + req_body);
  let reply = await r.subrequest("/_kvstore/put", { method: "POST", body: req_body });
  if (reply.status == 200) {
    r.log("Stored token in remote KV");
  } else {
    r.warn("Failed to store token in remote KV (" + reply.status + "): " + reply.responseText);
  }
}

async function read(r, key) {
  var req_body = buildEtcdMessageBody(key);
  r.log("ETCD read request body: " + req_body);
  let reply = await r.subrequest("/_kvstore/range", { method: "POST", body: req_body });
  if (reply.status == 200) {
    var resp_body = JSON.parse(reply.responseText);
    if ("kvs" in resp_body && "value" in resp_body.kvs[0]) {
      let remote_session_value = base64Decode(resp_body.kvs[0].value);
      r.log("Found key " + r.variables.cookie_auth_token + " with value " + remote_session_value);
      return remote_session_value;
    }
  }

  r.log("No existing session found on ETCD.");
  return;
}
