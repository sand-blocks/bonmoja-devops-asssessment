FROM hashicorp/http-echo:latest
ENTRYPOINT ["/http-echo", "-text=HI BONMOJA, I'M RUNNING ON ECS DEMO"]

