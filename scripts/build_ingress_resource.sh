#!/bin/bash
cat - << EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: $ingress_name
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: "$ingress_service_name"
          servicePort: 80
EOF
