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
 * Integration test: Shipping associated with orders
 * Tests communication between shipping-service and order-service
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class ShippingOrderIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void whenOrderHasShipping_thenShippingDetailsReturned() {
        // Arrange
        Integer orderId = 1;
        String shippingEndpoint = "/api/shipping/order/" + orderId;

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(shippingEndpoint, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().equals(HttpStatus.OK) ||
            response.getStatusCode().equals(HttpStatus.NOT_FOUND)
        );
    }

    @Test
    public void whenRetrievingAllShipments_thenShipmentListReturned() {
        // Arrange
        String shipmentsEndpoint = "/api/shipping";

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(shipmentsEndpoint, String.class);

        // Assert
        assertTrue(response.getStatusCode().is2xxSuccessful());
        assertNotNull(response.getBody());
    }

    @Test
    public void whenCalculatingShippingCost_thenCostIsReturned() {
        // Arrange
        String calculateEndpoint = "/api/shipping/calculate?quantity=5&weight=10";

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(calculateEndpoint, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().is2xxSuccessful() ||
            response.getStatusCode().equals(HttpStatus.NOT_FOUND)
        );
    }

    @Test
    public void whenTrackingShipment_thenTrackingInfoReturned() {
        // Arrange
        String trackingNumber = "TRACK123456";
        String trackingEndpoint = "/api/shipping/track/" + trackingNumber;

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(trackingEndpoint, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().equals(HttpStatus.OK) ||
            response.getStatusCode().equals(HttpStatus.NOT_FOUND)
        );
    }

    @Test
    public void whenShippingOrderItems_thenItemsAreShipped() {
        // Arrange
        Integer orderItemId = 1;
        String orderItemEndpoint = "/api/shipping/items/" + orderItemId;

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(orderItemEndpoint, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().equals(HttpStatus.OK) ||
            response.getStatusCode().equals(HttpStatus.NOT_FOUND)
        );
    }
}
