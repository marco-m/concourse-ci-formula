minio:
  lookup:
    access_key: CHANGEME-b8e46114a7f64561
    secret_key: CHANGEME-05ba7d7c95362608
    endpoint: {{ 'http://' + salt['network.interface_ip']('eth0') + ':9000' }}
    buckets:
      - channel
      - test
      - caproni-artifacts
      - caproni-release
