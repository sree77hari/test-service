FROM default-route-openshift-image-registry.apps.cluster-gbtvh.sandbox942.opentlc.com/openshift/test-service
COPY a /opt/app-root/src
COPY b /opt/app-root/src
COPY c /opt/app-root/src
