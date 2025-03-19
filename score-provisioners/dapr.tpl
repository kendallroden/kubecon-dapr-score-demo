- op: set
  path: services.placement.image
  value: daprio/dapr
- op: set
  path: services.placement.command
  value: ["./placement", "--port", "50006"]
- op: set
  path: services.placement.ports
  value:
  - target: 50006
    published: "50006"
- op: set
  path: services.scheduler.image
  value: daprio/dapr
- op: set
  path: services.scheduler.command
  value: ["./scheduler", "--port", "50007"]
- op: set
  path: services.scheduler.ports
  value:
  - target: 50007
    published: "50007"
- op: set
  path: services.scheduler.volumes
  value:
  #- type: volume
  #  source: scheduler-data
  #  target: /data
  - type: tmpfs
    target: /data
    tmpfs:
      size: 128
#- op: set
#  path: volumes.scheduler-data.name
#  value: scheduler-data
#- op: set
#  path: volumes.scheduler-data.driver
#  value: local
{{ range $name, $cfg := .Compose.services }}
{{ if dig "annotations" "dapr.io/enabled" false $cfg }}
- op: set
  path: services.{{ $name }}-sidecar.image
  value: daprio/daprd:latest
- op: set
  path: services.{{ $name }}-sidecar.command
  value: ["./daprd", "--app-id={{ dig "annotations" "dapr.io/app-id" "" $cfg }}", "--app-port={{ dig "annotations" "dapr.io/app-port" "" $cfg }}", "--enable-api-logging={{ dig "annotations" "dapr.io/enable-api-logging" false $cfg }}", "--placement-host-address=placement:50006", "--resources-path=/components"]
- op: set
  path: services.{{ $name }}-sidecar.network_mode
  value: service:{{ $name }}
- op: set
  path: services.{{ $name }}-sidecar.volumes
  value:
  - type: bind
    source: .score-compose/mounts/components/
    target: /components
- op: set
  path: services.{{ $name }}-sidecar.depends_on
  value:
    placement:
      condition: service_started
      required: true
{{ end }}
{{ end }}