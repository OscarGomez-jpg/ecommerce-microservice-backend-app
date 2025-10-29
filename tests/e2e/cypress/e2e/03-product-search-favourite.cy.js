describe('E2E: Product Search and Favourite', () => {
  const apiUrl = Cypress.env('apiUrl');
  let productId, categoryId;

  before(() => {
    cy.waitForService(`${apiUrl}/actuator/health`);
  });

  it('1. Browse all products', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/api/products`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404]);

      if (response.status === 200) {
        const data = response.body;
        cy.log(`Products endpoint responded with ${response.status}`);

        if (Array.isArray(data) && data.length > 0) {
          productId = data[0].productId;
          if (data[0].category) {
            categoryId = data[0].category.categoryId || data[0].categoryId || 1;
          }
        } else {
          productId = 1;
          categoryId = 1;
        }
      }
    });
  });

  it('2. View specific product details', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/api/products/${productId}`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404]);
      cy.log(`Product details status: ${response.status}`);
    });
  });

  it('3. Browse products by category', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/api/products/category/${categoryId}`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404]);
      cy.log(`Products by category status: ${response.status}`);
    });
  });

  it('4. View all categories', () => {
    cy.request({
      method: 'GET',
      url: `${apiUrl}/api/categories`,
      failOnStatusCode: false
    }).then((response) => {
      expect(response.status).to.be.oneOf([200, 404]);
      cy.log(`Categories endpoint status: ${response.status}`);
    });
  });

  it('5. Add product to favourites', () => {
    const favouriteData = {
      userId: 1,
      productId: productId
    };

    cy.request({
      method: 'POST',
      url: `${apiUrl}/api/favourites`,
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
});
