local grafana = import 'grafonnet-lib/grafonnet/grafana.libsonnet';
local prometheus = grafana.prometheus;

local singlestatHeight = 100;
local singlestatGuageHeight = 150;

grafana.dashboard.new('Chaos Dashboard')


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