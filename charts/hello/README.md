# Hello

[Hello World](https://github.com/cloudecho/hello-world-go) - A hello-world program written in go lang.

## TL;DR;

```console
$ helm repo add cloudecho https://cloudecho.github.io/charts/
$ helm repo update
$ helm install my-hello cloudecho/hello -n default --version=0.1.2
```

## Introduction

This chart deploys hello on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes v1.14+

## Installing the Chart

To install the chart with the release name `my-hello`:

```console
$ helm install my-hello cloudecho/hello -n default --version=0.1.2
```

The command deploys hello on the Kubernetes cluster in the default configuration. The [configuration](#configuration) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `my-hello`:

```console
$ helm delete my-hello -n default
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the `hello` chart and their default values.

|                 Parameter                  |                                                      Description                                                       |      Default      |
|--------------------------------------------|------------------------------------------------------------------------------------------------------------------------|-------------------|
| replicaCount                               |                                                                                                                        | `1`               |
| image.repository                           |                                                                                                                        | `cloudecho/hello` |
| image.pullPolicy                           |                                                                                                                        | `IfNotPresent`    |
| image.tag                                  | Overrides the image tag whose default is the chart appVersion.                                                         | `""`              |
| imagePullSecrets                           |                                                                                                                        | `[]`              |
| nameOverride                               |                                                                                                                        | `""`              |
| fullnameOverride                           |                                                                                                                        | `""`              |
| serviceAccount.create                      | Specifies whether a service account should be created                                                                  | `false`           |
| serviceAccount.annotations                 | Annotations to add to the service account                                                                              | `{}`              |
| serviceAccount.name                        | The name of the service account to use. If not set and create is true, a name is generated using the fullname template | `""`              |
| podAnnotations                             |                                                                                                                        | `{}`              |
| podSecurityContext                         |                                                                                                                        | `{}`              |
| securityContext                            |                                                                                                                        | `{}`              |
| service.type                               |                                                                                                                        | `ClusterIP`       |
| service.port                               |                                                                                                                        | `8080`            |
| ingress.enabled                            |                                                                                                                        | `false`           |
| ingress.className                          |                                                                                                                        | `""`              |
| ingress.annotations                        |                                                                                                                        | `{}`              |
| ingress.tls                                |                                                                                                                        | `[]`              |
| resources                                  |                                                                                                                        | `{}`              |
| autoscaling.enabled                        |                                                                                                                        | `false`           |
| autoscaling.minReplicas                    |                                                                                                                        | `1`               |
| autoscaling.maxReplicas                    |                                                                                                                        | `100`             |
| autoscaling.targetCPUUtilizationPercentage |                                                                                                                        | `80`              |
| nodeSelector                               |                                                                                                                        | `{}`              |
| tolerations                                |                                                                                                                        | `[]`              |
| affinity                                   |                                                                                                                        | `{}`              |


Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```console
$ helm install my-hello cloudecho/hello -n default --version=0.1.2 --set replicaCount=1
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while
installing the chart. For example:

```console
$ helm install my-hello cloudecho/hello -n default --version=0.1.2 --values values.yaml
```
