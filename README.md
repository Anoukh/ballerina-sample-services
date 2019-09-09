# ballerina-sample-services

This repository contains 4 Ballerina services that I used to test Ballerina Observability.
It tests http services, http clients and jdbc clients.

All four service can be run using the following commands.
Since all four services can not start up the prometheus endpoint on port 9797, the default port has been overridden.

```
ballerina run store.bal --b7a.observability.enabled=true 
ballerina run order.bal --b7a.observability.enabled=true --b7a.observability.metrics.prometheus.port=9798 
ballerina run product.bal --b7a.observability.enabled=true --b7a.observability.metrics.prometheus.port=9799 
ballerina run inventory.bal --b7a.observability.enabled=true --b7a.observability.metrics.prometheus.port=9800
```

Following is a sample `prometheus.yml` file that can be used to configure prometheus to scrape data from all 4 endpoints.
(172.17.0.1 is the docker ip and works for Ubuntu. MAC users might have to use local IP or 0.0.0.0 instead).

```
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['172.17.0.1:9797', '172.17.0.1:9798', '172.17.0.1:9799', '172.17.0.1:9800']
```

Sample cURL command 
`http://localhost:9090/StoreService/processOrder?orderId=2`

#### TODO
Use the observe package to test the tracing and metrics user apis.  
Tracing of Ballerina worker interactions.  
Error reporting of Services and Clients.  
Log reporting to active span.

##### Supported Version
Ballerina 1.0.0-beta-SNAPSHOT  
Language specification 2019R2  
Ballerina tool 1.0.0  

For more information on Ballerina Observability, Refer https://ballerina.io/learn/how-to-observe-ballerina-code/
