local grafana = import 'grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;

local singlestatHeight = 100;
local singlestatGuageHeight = 150;

grafana.dashboard.new(
  'Chaos Dashboard: Workload performance - USE method',
  description='Summary metrics for Openshift/Kubernetes workload',
  tags=['kubernetes', 'openshift'],
  time_from='now-1h',
)

// Prometheus datasource template variable
.addTemplate(
  grafana.template.datasource(
    'datasource',
    'prometheus',
    '',
  ) {
    label: 'Datasource'
  },
)

// project or namespace (workloads)
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

// pod 
.addTemplate(
  grafana.template.new(
    'pod',
    '$datasource',
    'label_values(kube_pod_info{namespace="$namespace"}, pod)',
    '',
    regex='',
    refresh=2,
  ) {
    label: 'Pod',
    type: 'query',
    multi: false,
    includeAll: true,
  },
)

// prometheus interval
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

// Ingress route
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

// Workload CPU utilization, saturation and errors
.addRow(
  grafana.row.new(
    collapse=true,
    title='Workload: CPU',
  )
  .addPanel(
    grafana.graphPanel.new(
      'CPU Utilization (Pod)',
      format='percent',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_cpu_usage_seconds_total{namespace="$namespace",pod="$pod",container!~"POD"}[$interval])) by (pod)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'CPU Utilization (Workload)',
      format='percent',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_cpu_usage_seconds_total{namespace="$namespace",container!~"POD"}[$interval])) by (pod)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'CPU Saturation',
      format='percent',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_cpu_cfs_throttled_seconds_total{namespace="$namespace",container!~"POD"}[$interval])) by (pod)',
      )
    )
  )
)

// Workload Memory utilization, saturation and errors
.addRow(
  grafana.row.new(
    collapse=true,
    title='Workload: Memory',
  )
   .addPanel(
    grafana.graphPanel.new(
      'Memory Utilization (Pod)',
      format='bytes',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(container_memory_working_set_bytes{namespace="$namespace",pod="$pod"}) by (pod)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Memory Utilization (Workload)',
      format='bytes',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(container_memory_working_set_bytes{namespace="$namespace"}) by (pod)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Memory Saturation',
      format='bytes',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(container_memory_working_set_bytes{namespace="$namespace"}) by (pod) / sum(label_join(kube_pod_container_resource_limits_memory_bytes,"pod", "", "container")) 	by (name)',
      )
    )
  )
)

// Workload Disk/IO utilization, saturation and errors
.addRow(
  grafana.row.new(
    collapse=true,
    title='Workload: Disk/IO',
  )
  .addPanel(
    grafana.graphPanel.new(
      'Bytes write/s',
      format='bytes',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_fs_writes_bytes_total{namespace="$namespace"}[$interval])) by (pod)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Bytes read/s',
      format='bytes',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_fs_reads_bytes_total{namespace="$namespace"}[$interval])) by (pod)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Total bytes/s',
      format='bytes',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_fs_reads_bytes_total{namespace="$namespace"}[$interval])) by (pod) + sum(rate(container_fs_writes_bytes_total{namespace="$namespace"}[$interval])) by (pod)',
      )
    )
  )
)

// Workload Network utilization, saturation and errors
.addRow(
  grafana.row.new(
    collapse=true,
    title='Workload: Network',
  )
  // receive
  .addPanel(
    grafana.graphPanel.new(
      'Net received bytes/s',
      format="bytes",
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_network_receive_bytes_total{namespace="$namespace"}[$interval])) by (name)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Net received packets/s',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_network_receive_packets_total{namespace="$namespace"}[$interval])) by (pod)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Net received errors/s',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_network_receive_errors_total{namespace="$namespace"}[$interval])) by (pod)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Net received packet drop/s',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_network_receive_packets_dropped_total{namespace="$namespace"}[$interval])) by (pod)',
      )
    )
  )

  // transmit
  .addPanel(
    grafana.graphPanel.new(
      'Net transmitted bytes/s',
      format="bytes",
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_network_transmit_bytes_total{namespace="$namespace"}[$interval])) by (pod)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Net transmitted packets/s',
      format="bytes",
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_network_transmit_packets_total{namespace="$namespace"}[$interval])) by (pod)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Net transmitted errors/s',
      format="bytes",
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_network_transmit_errors_total{namespace="$namespace"}[$interval])) by (name)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Net transmitted packet drop/s',
      format="bytes",
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_network_transmit_packets_dropped_total{namespace="$namespace"}[$interval])) by (pod)',
      )
    )
  )
  // total
  .addPanel(
    grafana.graphPanel.new(
      'Net Total bytes/s',
      format="bytes",
      datasource='$datasource',
      span=12,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(container_network_transmit_bytes_total{namespace="$namespace"}[$interval])) by (pod) + sum(rate(container_network_receive_bytes_total{namespace="$namespace"}[$interval])) by (pod)',
      )
    )
  )
)