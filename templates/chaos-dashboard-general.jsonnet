local grafana = import 'grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;

local singlestatHeight = 100;
local singlestatGuageHeight = 150;

grafana.dashboard.new(
  'Chaos Dashboard: General performance', 
  tags=['kubernetes', 'openshift']
)


// Prometheus datasource template variable
.addTemplate(
  grafana.template.datasource(
    'datasource',
    'prometheus',
    '',
  )
)

// OpenShift project or namespace (workloads)
.addTemplate(
  grafana.template.new(
    'namespace',
    '$datasource',
    'label_values(kube_pod_info, namespace)',
    '',
    regex='',
    refresh=2,
  ) {
    label: 'Namespace',
    type: 'query',
    multi: false,
    includeAll: true,
  },
)

// OCP Cluster Node
.addTemplate(
  grafana.template.new(
    'cluster_node',
    '$datasource',
    'label_values(kube_node_role, node)',
    '',
    refresh=2,
  ) {
    label: 'Cluster Node',
    type: 'query',
    multi: true,
    includeAll: false,
  },
)

// Prometheus interval
.addTemplate(
  grafana.template.new(
    'interval',
    '$datasource',
    '$__auto_interval_period',
    label='interval',
    refresh='time',
  ) {
    type: 'interval',
    query: '1m,2m,3m,4m,5m,10m,15m,30m,1h',
    auto: false,
  },
)

// Ingress Operator Route
.addTemplate(
  grafana.template.new(
    'route',
    '$datasource',
    'label_values(openshift_route_info{to_kind="Service"}, route)',
    '',
    refresh=2,
  ) {
    label: 'Ingress Route',
    type: 'query',
    multi: false,
    includeAll: false,
  },
)

// Pod stats
.addRow(
  grafana.row.new(
    collapse=true,
    title='Pod Stats',
  )
  .addPanel(
    grafana.singlestat.new(
      'Pods Total',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_status_phase{namespace="$namespace"})',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Pods Running',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_status_phase{phase="Running",namespace="$namespace"})',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Pods Succeeded',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_status_phase{phase="Succeeded",namespace="$namespace"})',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Pods Pending',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
      thresholds=0,
      colors=['rgb(230, 22, 46)'],
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_status_phase{phase="Pending",namespace="$namespace"})',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Pods Failed',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
      thresholds=0,
      colors=['rgb(230, 22, 46)'],
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_status_phase{phase="Failed",namespace="$namespace"})',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Pods Unknown',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
      thresholds=0,
      colors=['rgb(230, 22, 46)'],
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_status_phase{phase="Unknown",namespace="$namespace"})',
      )
    )
  )
  // end row
)

// Container stats
.addRow(
  grafana.row.new(
    collapse=true,
    title='Container Stats',
  )
  .addPanel(
    grafana.singlestat.new(
      'Containers Running',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_container_status_running{namespace="$namespace"})',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Containers Waiting',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
      colors=['rgb(230, 22, 46)'],
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_container_status_waiting{namespace="$namespace"})',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Containers Terminating',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
      colors=['rgb(230, 22, 46)'],
      span=3,
      thresholds=0,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_container_status_terminated{namespace="$namespace"})',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Containers Restarts (Last 30 Minutes)',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
      colors=['rgb(230, 22, 46)'],
      span=3,
      thresholds=0,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(delta(kube_pod_container_status_restarts_total{namespace="$namespace"}[30m]))',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Container Failed to Start',
      datasource='$datasource',
      height=singlestatHeight,
      gaugeShow=false,
      colorBackground=true,
      colors=['rgb(230, 22, 46)'],
      span=4,
      thresholds=0,
    )
    .addTarget(
      grafana.prometheus.target(
        'kube_pod_container_status_waiting_reason{reason!="ContainerCreating",namespace="$namespace"} > 0',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'CPU Cores Requested by Containers',
      datasource='$datasource',
      height=singlestatHeight,
      span=4,
      sparklineShow=true,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_container_resource_requests_cpu_cores{namespace="$namespace"})',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Memory Requested By Containers',
      datasource='$datasource',
      format='decbytes',
      height=singlestatHeight,
      span=4,
      sparklineShow=true,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_container_resource_requests_memory_bytes{namespace="$namespace"})',
      )
    )
  )
)

// Latency, Traffic, Error and Saturation/ golden signal - haproxy stats
// SLO, SLI and SLA, Error Budget
.addRow(
  grafana.row.new(
    collapse=true,
    title='Workload - QPS, Latency and Errors',
  )
  // Request
  .addPanel(
    grafana.graphPanel.new(
      'Connection/Request rate (qps)',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(haproxy_backend_connections_total{route="$route"}[$interval]))', //add interval variable/tmplate
        legendFormat='Total HTTP connections (backend)'
      )
    )
  )
  .addPanel(  
    grafana.graphPanel.new(
      'Response rate (resp/s)',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(haproxy_backend_http_responses_total{route="$route"}[$interval]))', //add interval variable/tmplate
        legendFormat='Total HTTP response (backend)'
      )
    )
  )
  .addPanel(  
    grafana.graphPanel.new(
      'Response rate (resp/s) 2xx',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(haproxy_backend_http_responses_total{route="$route",code="2xx"}[$interval]))', //add interval variable/tmplate
        legendFormat='Response rate 2xx (backend)'
      )
    )
  )
  // End Request
  // Errors
  .addPanel(
    grafana.graphPanel.new(
      'HTTP response code 4xx',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(haproxy_backend_http_responses_total{route="$route",code="4xx"}[$interval]))', //add interval variable/tmplate
        legendFormat='Error rate - 4xx'
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'HTTP response code 5xx',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(haproxy_backend_http_responses_total{route="$route",code="5xx"}[1m]))', //add interval variable/tmplate
        legendFormat='Error rate - 5xx'
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'HTTP connection errors',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(haproxy_backend_connection_errors_total{route="$route"}[1m]))', //add interval variable/tmplate
        legendFormat='HTTP connection error rate'
      )
    )
  )
  // End Error
  .addPanel(
    grafana.graphPanel.new(
      'Connection rate (conn/s)',
      datasource='$datasource',
      span=6,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(haproxy_frontend_connections_total{frontend=~"public|public_ssl"}[1m]))', //add interval variable/tmplate
        legendFormat='Total HTTP connections'
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'HTTP request/response rate (rps)',
      datasource='$datasource',
      span=6,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(haproxy_frontend_http_responses_total{frontend=~"public|public_ssl"}[1m])) ', //add interval variable/tmplate
        legendFormat='Total HTTP response'
      )
    )
  )
)

// 

// Workload health
.addRow(
  grafana.row.new(
    collapse=true,
    title='Workload Health',
  )

  // Workload Health Singlestat
  .addPanel(  
    grafana.singlestat.new(
      'Workload Pod Usage',
      datasource='$datasource',
      format='percent',
      gaugeShow=true,
      height=singlestatGuageHeight,
      span=3,
      thresholds='80,90',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_info) / sum(kube_node_status_allocatable_pods) * 100',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Workload CPU Usage',
      datasource='$datasource',
      format='percent',
      gaugeShow=true,
      height=singlestatGuageHeight,
      span=3,
      thresholds='80,90',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_container_resource_requests_cpu_cores) / sum(kube_node_status_allocatable_cpu_cores) * 100',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Workload Memory Usage',
      datasource='$datasource',
      format='percent',
      gaugeShow=true,
      height=singlestatGuageHeight,
      span=3,
      thresholds='80,90',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_container_resource_requests_memory_bytes) / sum(kube_node_status_allocatable_memory_bytes) * 100',
      )
    )
  )
  .addPanel(
    grafana.singlestat.new(
      'Workload Disk Usage',
      datasource='$datasource',
      format='percentunit',
      gaugeShow=true,
      height=singlestatGuageHeight,
      span=3,
      thresholds='80,90',
    )
    .addTarget(
      grafana.prometheus.target(
        '(sum (node_filesystem_size_bytes) - sum (node_filesystem_free_bytes)) / sum (node_filesystem_size_bytes)',
      )
    )
  )

  // Cluster Health Graphs
  .addPanel(
    grafana.graphPanel.new(
      'Cluster Pod Capacity',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_node_status_allocatable_pods)',
        legendFormat='allocatable'
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_node_status_capacity_pods)',
        legendFormat='capacity'
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_info)',
        legendFormat='requested'
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Cluster CPU Capacity',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_node_status_capacity_cpu_cores)',
        legendFormat='allocatable'
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_node_status_allocatable_cpu_cores)',
        legendFormat='capacity'
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_container_resource_requests_cpu_cores)',
        legendFormat='requested'
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Cluster Mem Capacity',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_node_status_allocatable_memory_bytes)',
        legendFormat='allocatable'
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_node_status_capacity_memory_bytes)',
        legendFormat='capacity'
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(kube_pod_container_resource_requests_memory_bytes)',
        legendFormat='requested'
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Cluster Disk Capacity',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(node_filesystem_size_bytes) - sum(node_filesystem_free_bytes)',
        legendFormat='usage'
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(node_filesystem_size_bytes)',
        legendFormat='limit'
      )
    )
  )
)

// Node health
.addRow(
  grafana.row.new(
    collapse=true,
    title='Node Health',
  )
)