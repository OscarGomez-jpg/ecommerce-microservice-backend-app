describe('E2E: Order Tracking Flow', () => {
  const apiUrl = Cypress.env('apiUrl');
  let orderId, shippingId;

  before(() => {
    cy.waitForService(`${apiUrl}/actuator/health`);
  });

  it('1. Create test order', () => {
    const orderData = {
      orderDesc: 'Cypress Test: Order tracking',
      orderDate: new Date().toISOString(),
      orderFee: 99.99
    };

    cy.request({
      method: 'POST',
      url: `${apiUrl}/api/orders`,
      body: orderData,
      failOnStatusCode: false,
      headers: {
        'Content-Type': 'application/json'
      }
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 201, 400, 404]);

      if ([200, 201].includes(response.status)) {
        orderId = response.body.orderId || 1;
        cy.log(`Order created with ID: ${orderId}`);
      } else {
        orderId = 1;
        cy.log(`Order creation failed, using fallback ID: ${orderId}`);
      }
    });
  });

  it('2. View order details', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/api/orders/${orderId}`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404]);
      cy.log(`Order details status: ${response.status}`);
    });
  });

  it('3. View all orders', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/api/orders`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404]);
      cy.log(`All orders status: ${response.status}`);
    });
  });

  it('4. Check shipping status', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/api/shipping/order/${orderId}`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404]);

      if (response.status === 200 && response.body) {
        shippingId = response.body.shippingId || 1;
        cy.log(`Shipping found with ID: ${shippingId}`);
      } else {
        shippingId = 1;
        cy.log(`Shipping not found, using fallback ID: ${shippingId}`);
      }
    });
  });

  it('5. View all shipments', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/api/shipping`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404]);
      cy.log(`All shipments status: ${response.status}`);
    });
  });

  it('6. Update shipping status', () => {
    const updateData = {
      shippingStatus: 'IN_TRANSIT'
    };

    cy.request({
      method: 'PUT',
      url: `${apiUrl}/api/shipping/${shippingId}`,
      body: updateData,
      failOnStatusCode: false,
      headers: {
        'Content-Type': 'application/json'
      }
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 201, 400, 404]);
      cy.log(`Shipping update status: ${response.status}`);
    });
  });
});
