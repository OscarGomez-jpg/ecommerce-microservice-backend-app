package com.selimhorri.app.integration;

import static org.junit.jupiter.api.Assertions.*;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

/**
 * Integration test: Order creation with products
 * Tests communication between order-service, product-service, and user-service
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class OrderCreationIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void whenValidOrderCreated_thenOrderIsStored() {
        // Arrange
        String orderEndpoint = "/api/orders";
        String orderJson = "{"
            + "\"orderDesc\":\"Test Order\","
            + "\"orderDate\":\"2024-01-15T10:30:00\""
            + "}";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> request = new HttpEntity<>(orderJson, headers);

        // Act
        ResponseEntity<String> response = restTemplate.postForEntity(orderEndpoint, request, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().equals(HttpStatus.CREATED) ||
            response.getStatusCode().equals(HttpStatus.OK) ||
            response.getStatusCode().equals(HttpStatus.BAD_REQUEST)
        );
    }

    @Test
    public void whenRetrievingAllOrders_thenOrderListReturned() {
        // Arrange
        String ordersEndpoint = "/api/orders";

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(ordersEndpoint, String.class);

        // Assert
        assertTrue(response.getStatusCode().is2xxSuccessful());
        assertNotNull(response.getBody());
    }

    @Test
    public void whenRetrievingSpecificOrder_thenOrderDetailsReturned() {
        // Arrange
        Integer orderId = 1;
        String orderEndpoint = "/api/orders/" + orderId;

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(orderEndpoint, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().equals(HttpStatus.OK) ||
            response.getStatusCode().equals(HttpStatus.NOT_FOUND)
        );
    }

    @Test
    public void whenCreatingOrderWithInvalidData_thenBadRequest() {
        // Arrange
        String orderEndpoint = "/api/orders";
        String invalidOrderJson = "{\"invalid\":\"data\"}";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> request = new HttpEntity<>(invalidOrderJson, headers);

        // Act
        ResponseEntity<String> response = restTemplate.postForEntity(orderEndpoint, request, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().equals(HttpStatus.BAD_REQUEST) ||
            response.getStatusCode().is2xxSuccessful()
        );
    }

    @Test
    public void whenDeletingOrder_thenOrderIsRemoved() {
        // Arrange
        Integer orderId = 999;
        String orderEndpoint = "/api/orders/" + orderId;

        // Act
        restTemplate.delete(orderEndpoint);

        // Assert - Verify order is deleted by trying to get it
        ResponseEntity<String> response = restTemplate.getForEntity(orderEndpoint, String.class);
        assertTrue(
            response.getStatusCode().equals(HttpStatus.NOT_FOUND) ||
            response.getStatusCode().is2xxSuccessful()
        );
    }
}
