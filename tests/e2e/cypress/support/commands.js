// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************

// Custom command for API requests with better error handling
Cypress.Commands.add('apiRequest', (method, url, body = null, expectedStatuses = [200, 201]) => {
  const options = {
    method: method,
    url: url,
    failOnStatusCode: false,
    headers: {
      'Content-Type': 'application/json'
    }
  };

  if (body) {
    options.body = body;
  }

  return cy.request(options).then((response) => {
    expect(expectedStatuses).to.include(response.status);
    return cy.wrap(response);
  });
});

// Custom command to wait for service to be ready
Cypress.Commands.add('waitForService', (endpoint, maxRetries = 10) => {
  const checkService = (retries) => {
    if (retries === 0) {
      throw new Error(`Service not ready after ${maxRetries} attempts`);
    }

    return cy.request({
      url: endpoint,
      failOnStatusCode: false
    }).then((response) => {
      if (response.status !== 200) {
        cy.wait(2000);
        return checkService(retries - 1);
      }
      return cy.wrap(response);
    });
  };

  return checkService(maxRetries);
});
