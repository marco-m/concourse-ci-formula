minio:
  lookup:
    access_key: minio
    secret_key: CHANGEME-05ba7d7c95362608
    endpoint: {{ 'http://' + salt['network.interface_ip']('eth1') + ':9000' }}
    buckets:
      - channel
      - test
      - caproni
