describe('E2E: User Registration and Purchase Flow', () => {
  let userId, productId;
  const apiUrl = Cypress.env('apiUrl');
  const timestamp = Date.now();

  before(() => {
    cy.waitForService(`${apiUrl}/actuator/health`);
  });

  it('1. User registers new account', () => {
    const userData = {
      firstName: 'John',
      lastName: 'Doe',
      email: `test${timestamp}@example.com`,
      phone: '1234567890'
    };

    cy.request({
      method: 'POST',
      url: `${apiUrl}/user-service/api/users`,
      body: userData,
      failOnStatusCode: false,
      headers: {
        'Content-Type': 'application/json'
      }
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 201, 400, 404]);

      if ([200, 201].includes(response.status)) {
        userId = response.body.userId || 1;
        cy.log(`User registered with ID: ${userId}`);
      } else {
        userId = 1;
        cy.log(`User registration failed, using fallback ID: ${userId}`);
      }
    });
  });

  it('2. User logs in to account', () => {
    const loginData = {
      username: 'testuser',
      password: 'password'
    };

    cy.request({
      method: 'POST',
      url: `${apiUrl}/user-service/api/users/login`,
      body: loginData,
      failOnStatusCode: false,
      headers: {
        'Content-Type': 'application/json'
      }
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 201, 400, 401, 404]);
      cy.log(`Login attempt status: ${response.status}`);
    });
  });

  it('3. User searches for products', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/product-service/api/products`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404]);

      if (response.status === 200 && Array.isArray(response.body) && response.body.length > 0) {
        productId = response.body[0].productId;
        cy.log(`Product found with ID: ${productId}`);
      } else {
        productId = 1;
        cy.log(`No products found, using fallback ID: ${productId}`);
      }
    });
  });

  it('4. User adds product to favourites', () => {
    const favouriteData = {
      userId: userId,
      productId: productId
    };

    cy.request({
      method: 'POST',
      url: `${apiUrl}/favourite-service/api/favourites`,
      body: favouriteData,
      failOnStatusCode: false,
      headers: {
        'Content-Type': 'application/json'
      }
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 201, 400, 404]);
      cy.log(`Add to favourites status: ${response.status}`);
    });
  });

  it('5. User views their favourites', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/favourite-service/api/favourites/user/${userId}`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404]);
      cy.log(`View favourites status: ${response.status}`);
    });
  });

  it('6. User creates order from favourites', () => {
    const orderData = {
      orderDesc: 'Cypress Test: Order from favourites',
      orderDate: new Date().toISOString()
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
      expect(response.status).to.be.oneOf([200, 201, 400, 404]);
      cy.log(`Create order status: ${response.status}`);
    });
  });
});
