services:
  etcd:
    image: gcr.io/etcd-development/etcd:v3.5.6
    environment:
      - ETCD_NAME=node
      - ETCD_ROOT_PASSWORD=${etcd_root_password}
      - ETCD_INITIAL_ADVERTISE_PEER_URLS=http://0.0.0.0:2380
      - ETCD_LISTEN_PEER_URLS=http://0.0.0.0:2380
      - ETCD_ADVERTISE_CLIENT_URLS=http://0.0.0.0:2379
      - ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379
      - ETCD_INITIAL_CLUSTER=node=http://0.0.0.0:2380
      - ETCD_LOG_OUTPUTS=stdout
      - ETCD_LOG_LEVEL=debug
    ports:
      - 2379:2379
  nginx:
    image: ${nginx_plus_docker_image}
    volumes:
      - ../files/nginx.conf:/etc/nginx/nginx.conf:ro
      - ../files/frontend.conf:/etc/nginx/conf.d/frontend.conf:ro
      - ../files/openid_connect.js:/etc/nginx/conf.d/openid_connect.js:ro
      - ../files/openid_connect.server_conf:/etc/nginx/conf.d/openid_connect.server_conf:ro
      - ../files/util.js:/etc/nginx/conf.d/util.js:ro
      - ./external_kvdb.server_conf:/etc/nginx/conf.d/external_kvdb.server_conf:ro
      - ./openid_connect_configuration.conf:/etc/nginx/conf.d/openid_connect_configuration.conf:ro
    ports:
      - 8010:8010
    depends_on:
      - etcd
