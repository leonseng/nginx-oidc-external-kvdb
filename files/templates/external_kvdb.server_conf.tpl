    location /_kvstore/ {
        internal;
        proxy_pass ${etcd3_api_endpoint}/v3/kv/;
    }
