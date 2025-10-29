# E2E Tests with Cypress

## Overview

This directory contains End-to-End tests for the E-Commerce microservices using **Cypress**.

## Test Suites

### 1. Complete Checkout Flow (`01-complete-checkout-flow.cy.js`)
Tests the full purchase workflow:
- Browse products
- View product details
- Create order
- Process payment
- Check shipping
- View order history

### 2. User Registration & Purchase (`02-user-registration-purchase.cy.js`)
Tests user account flow:
- User registration
- User login
- Product search
- Add to favourites
- View favourites
- Create order from favourites

### 3. Product Search & Favourite (`03-product-search-favourite.cy.js`)
Tests product browsing:
- Browse all products
- View product details
- Browse by category
- View categories
- Add to favourites

### 4. Order Tracking (`04-order-tracking.cy.js`)
Tests order management:
- Create order
- View order details
- View all orders
- Check shipping status
- Update shipping status

### 5. Payment & Refund (`05-payment-refund-flow.cy.js`)
Tests payment processing:
- Create order
- Initiate payment
- Complete payment
- View payment details
- Initiate refund

## Setup

### Install Dependencies

```bash
cd tests/e2e
npm install
```

## Running Tests

### Interactive Mode (Local Development)

```bash
npm run test:e2e:open
```

This opens Cypress UI where you can:
- Select individual tests to run
- See tests executing in real-time
- Debug failing tests

### Headless Mode (CI/CD)

```bash
# Set API URL
export API_BASE_URL=http://192.168.49.2:30080

# Run all tests
npm run test:e2e

# Run specific test
npx cypress run --spec "cypress/e2e/01-complete-checkout-flow.cy.js"
```

### With Minikube

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)

# Run tests against Minikube
API_BASE_URL=http://$MINIKUBE_IP:30080 npm run test:e2e
```

## Reports

Cypress generates reports automatically:

- **HTML Reports**: `cypress/reports/mochawesome.html`
- **Screenshots**: `cypress/screenshots/` (captured only on failures)

**Note:** Videos are disabled by default to save space and time. Screenshots are enough for debugging failures.

### Clean Reports

```bash
npm run clean:reports
```

## Configuration

### Environment Variables

- `API_BASE_URL`: Base URL of API Gateway (default: `http://localhost:8080`)

### cypress.config.js

Main configuration file with:
- Base URL
- Test file patterns
- Report settings
- Video/screenshot settings

## CI/CD Integration

### Jenkins Pipeline

Already integrated! The pipeline automatically runs E2E tests when you set `RUN_E2E_TESTS=true`.

```
Parameters:
- SERVICE_NAME: ALL
- RUN_E2E_TESTS: true (to enable)
- DEPLOY_TO_MINIKUBE: true (required)
```

The pipeline will:
1. Deploy services to Minikube
2. Wait 30 seconds for services to be ready
3. Run all Cypress tests
4. Publish HTML report in Jenkins
5. Archive screenshots (only if tests fail)
```

## Troubleshooting

### Tests failing with connection errors

Check that services are running:
```bash
kubectl get pods -n ecommerce
curl http://$(minikube ip):30080/actuator/health
```

### Timeout errors

Increase timeout in `cypress.config.js`:
```javascript
defaultCommandTimeout: 10000, // 10 seconds
requestTimeout: 10000,
responseTimeout: 10000
```

### Missing dependencies

```bash
cd tests/e2e
rm -rf node_modules package-lock.json
npm install
```

## Best Practices

1. **Keep tests independent**: Each test should be able to run standalone
2. **Use fallback IDs**: Tests handle cases where resources don't exist
3. **Check status codes**: Accept multiple valid status codes (200, 404, etc.)
4. **Log important info**: Use `cy.log()` for debugging
5. **Don't hardcode data**: Use dynamic data (timestamps, etc.)

## Legacy Jest Tests

The old Jest tests are still available:
```bash
npm run test:jest
```

But **Cypress is the official E2E testing framework** for this project.
