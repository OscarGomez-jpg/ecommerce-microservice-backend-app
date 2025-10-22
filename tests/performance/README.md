# Performance Tests with Locust

## Setup

Install dependencies:
```bash
pip install -r requirements.txt
```

## Running Tests

### Local Testing
```bash
locust -f locustfile.py --host=http://localhost:8080
```

Then open http://localhost:8089 and configure:
- Number of users: 100
- Spawn rate: 10
- Host: http://localhost:8080

### Headless Mode (CI/CD)
```bash
locust -f locustfile.py --headless --users 100 --spawn-rate 10 \
  --run-time 5m --host=http://localhost:8080 \
  --html report.html --csv results
```

### Kubernetes Testing
```bash
# Port forward the API Gateway
kubectl port-forward svc/api-gateway 8080:8080 -n prod

# Run locust
locust -f locustfile.py --host=http://localhost:8080
```

### AWS EKS Testing
```bash
# Get the Load Balancer URL
LB_URL=$(kubectl get svc api-gateway -n prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Run locust
locust -f locustfile.py --host=http://$LB_URL:8080
```

## Test Scenarios

### BrowsingUser (Weight: 3)
Simulates users browsing products:
- 60% browsing all products
- 30% viewing specific products
- 10% browsing by category

### PurchasingUser (Weight: 2)
Simulates complete checkout flow:
1. Browse products
2. View product details
3. Add to favourites
4. Create order
5. Process payment
6. Complete payment
7. Check order status

### AdminUser (Weight: 1)
Simulates admin operations:
- Viewing all orders
- Viewing all payments
- Viewing all users
- Viewing all products
- Viewing shipping information

## Metrics to Monitor

- **Response Time**: Average time for requests
- **Throughput**: Requests per second
- **Error Rate**: Percentage of failed requests
- **Concurrent Users**: Number of simultaneous users
- **95th Percentile**: Response time for 95% of requests

## Expected Performance Baseline

For 100 concurrent users:
- Average response time: < 500ms
- 95th percentile: < 1000ms
- Error rate: < 1%
- Throughput: > 100 req/s

## Interpreting Results

### Good Performance
- Green lines in Locust UI
- Error rate < 1%
- Response times stable over time

### Performance Issues
- Red lines indicating errors
- Increasing response times
- High error rates (> 5%)

### Actions for Poor Performance
1. Scale up replicas in Kubernetes
2. Optimize database queries
3. Add caching layer
4. Review application logs
5. Check resource utilization
