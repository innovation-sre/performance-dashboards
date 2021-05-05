local grafana = import 'grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;

local singlestatHeight = 100;
local singlestatGuageHeight = 250;

grafana.dashboard.new(
  'Chaos Dashboard: Litmus Experiments', 
  tags=['kubernetes', 'openshift', 'Litmus Chaos']
)

// prometheus datasource
.addTemplate(
  grafana.template.datasource(
    'datasource',
    'prometheus',
    '',
  ) {
    label: 'Namespace Datasource',
  },
)

// prometheus datasource
.addTemplate(
  grafana.template.datasource(
    'litmus_datasource',
    'prometheus',
    '',
  ) {
    label: 'Litmus Datasource',
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

// namespace or project (workload)
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

// pod template
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
    multi: true,
    includeAll: true,
  },
)

// Litmus experiments
.addRow(
  grafana.row.new(
    collapse=true,
    title='Chaos Metrics',
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
    grafana.singlestat.new(
      'Total Experiments Run',
      datasource='$litmus_datasource',
      gaugeShow=true,
      height=singlestatGuageHeight,
      span=2,
      thresholds='100'
    )
    .addTarget(
      grafana.prometheus.target(
        "sum(litmuschaos_passed_experiments{chaosresult_namespace='$namespace'}) + sum(litmuschaos_failed_experiments{chaosresult_namespace='$namespace'}) + sum(litmuschaos_awaited_experiments{chaosresult_namespace='$namespace'})",
      )
    )
  )
  .addPanel(  
    grafana.singlestat.new(
      'Passed Experiments',
      datasource='$litmus_datasource',
      gaugeShow=true,
      height=singlestatGuageHeight,
      span=2,
      thresholds='100'
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(litmuschaos_passed_experiments{chaosresult_namespace="$namespace"})',
      )
    )
  )
  .addPanel(  
    grafana.singlestat.new(
      'Failed Experiments',
      datasource='$litmus_datasource',
      gaugeShow=true,
      span=2,
      height=singlestatGuageHeight,
      thresholds='1'
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(litmuschaos_failed_experiments{chaosresult_namespace="$namespace"})',
      )
    )
  )
  .addPanel(  
    grafana.singlestat.new(
      'Queued Experiments',
      datasource='$litmus_datasource',
      gaugeShow=true,
      span=2,
      height=singlestatGuageHeight,
      thresholds='1'
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(litmuschaos_awaited_experiments{chaosresult_namespace="$namespace"})',
      )
    )
  )
)

// Golden signals
.addRow(
  grafana.row.new(
    collapse=true,
    title='RED Method - Requests, Duration(Latency) and Errors Rates',
  )
  .addPanel(
    grafana.graphPanel.new(
      'Request/sec (QPS)',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(haproxy_backend_http_responses_total{exported_namespace="$namespace",code="2xx"}[$interval]))',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Latency (Request duration)',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'haproxy_server_http_average_response_latency_milliseconds{exported_namespace="$namespace"}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      'Error rate',
      datasource='$datasource',
      span=4,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(haproxy_backend_http_responses_total{exported_namespace="$namespace",code=~"4.+|5.+"}[$interval]))',
      )
    )
  )
)