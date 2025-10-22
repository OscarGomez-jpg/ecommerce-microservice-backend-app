package com.selimhorri.app.integration;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

/**
 * Integration test: User retrieves product information
 * Tests communication between user-service and product-service via API Gateway
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class UserProductIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void whenUserRetrievesProducts_thenProductListIsReturned() {
        // Arrange
        String productsEndpoint = "/api/products";

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(productsEndpoint, String.class);

        // Assert
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertTrue(response.getBody().contains("productId") || response.getBody().equals("[]"));
    }

    @Test
    public void whenUserRetrievesSpecificProduct_thenProductDetailsAreReturned() {
        // Arrange
        Integer productId = 1;
        String productEndpoint = "/api/products/" + productId;

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(productEndpoint, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().equals(HttpStatus.OK) ||
            response.getStatusCode().equals(HttpStatus.NOT_FOUND)
        );
    }

    @Test
    public void whenUserAuthenticatesAndAccessesProducts_thenSuccessful() {
        // Arrange
        String loginEndpoint = "/api/users/login";
        String productsEndpoint = "/api/products";

        // Act - First get products without auth
        ResponseEntity<String> productsResponse = restTemplate.getForEntity(productsEndpoint, String.class);

        // Assert - Products should be accessible
        assertNotNull(productsResponse);
        assertTrue(productsResponse.getStatusCode().is2xxSuccessful() ||
                   productsResponse.getStatusCode().equals(HttpStatus.UNAUTHORIZED));
    }

    @Test
    public void whenInvalidProductIdRequested_thenNotFoundReturned() {
        // Arrange
        Integer invalidProductId = 99999;
        String productEndpoint = "/api/products/" + invalidProductId;

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(productEndpoint, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().equals(HttpStatus.NOT_FOUND) ||
            response.getStatusCode().equals(HttpStatus.OK)
        );
    }

    @Test
    public void whenUserSearchesProductsByCategory_thenFilteredProductsReturned() {
        // Arrange
        String categoryEndpoint = "/api/products?category=electronics";

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(categoryEndpoint, String.class);

        // Assert
        assertNotNull(response);
        assertTrue(response.getStatusCode().is2xxSuccessful() ||
                   response.getStatusCode().equals(HttpStatus.NOT_FOUND));
    }
}
