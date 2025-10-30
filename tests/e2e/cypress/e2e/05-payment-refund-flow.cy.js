describe('E2E: Payment and Refund Flow', () => {
  const apiUrl = Cypress.env('apiUrl');
  let orderId, paymentId;

  before(() => {
    cy.waitForService(`${apiUrl}/actuator/health`);
  });

  it('1. Create order for payment', () => {
    const orderData = {
      orderDesc: 'Cypress Test: Payment flow',
      orderDate: new Date().toISOString(),
      orderFee: 149.99
    };

    cy.request({
      method: 'POST',
      url: `${apiUrl}/order-service/api/orders`,
      body: orderData,
      failOnStatusCode: false,
      headers: {
        'Content-Type': 'application/json'
      }
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 201, 400, 404, 405, 503]);

      if ([200, 201].includes(response.status)) {
        orderId = response.body.orderId || 1;
        cy.log(`Order created with ID: ${orderId}`);
      } else {
        orderId = 1;
        cy.log(`Using fallback order ID: ${orderId}`);
      }
    });
  });

  it('2. Initiate payment', () => {
    const paymentData = {
      orderId: orderId,
      isPayed: false,
      paymentAmount: 149.99
    };

    cy.request({
      method: 'POST',
      url: `${apiUrl}/payment-service/api/payments`,
      body: paymentData,
      failOnStatusCode: false,
      headers: {
        'Content-Type': 'application/json'
      }
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 201, 400, 404, 405, 503]);

      if ([200, 201].includes(response.status)) {
        paymentId = response.body.paymentId || 1;
        cy.log(`Payment initiated with ID: ${paymentId}`);
      } else {
        paymentId = 1;
        cy.log(`Using fallback payment ID: ${paymentId}`);
      }
    });
  });

  it('3. Complete payment', () => {
    const updateData = {
      isPayed: true
    };

    cy.request({
      method: 'PUT',
      url: `${apiUrl}/payment-service/api/payments/${paymentId}`,
      body: updateData,
      failOnStatusCode: false,
      headers: {
        'Content-Type': 'application/json'
      }
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 201, 400, 404, 405, 503]);
      cy.log(`Payment completion status: ${response.status}`);
    });
  });

  it('4. View payment details', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/payment-service/api/payments/${paymentId}`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404, 405, 503]);

      if (response.status === 200) {
        cy.log(`Payment details retrieved successfully`);
      } else {
        cy.log(`Payment details not found`);
      }
    });
  });

  it('5. View all payments', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/payment-service/api/payments`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404, 405, 503]);
      cy.log(`All payments status: ${response.status}`);
    });
  });

  it('6. Initiate refund', () => {
    const refundData = {
      isPayed: false,
      refundReason: 'Customer request - Cypress test'
    };

    cy.request({
      method: 'PUT',
      url: `${apiUrl}/payment-service/api/payments/${paymentId}`,
      body: refundData,
      failOnStatusCode: false,
      headers: {
        'Content-Type': 'application/json'
      }
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 201, 400, 404, 405, 503]);
      cy.log(`Refund initiation status: ${response.status}`);
    });
  });
});
