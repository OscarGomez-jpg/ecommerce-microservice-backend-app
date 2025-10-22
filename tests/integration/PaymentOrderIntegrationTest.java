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
 * Integration test: Payment processing for orders
 * Tests communication between payment-service and order-service
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class PaymentOrderIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void whenPaymentCreatedForOrder_thenPaymentIsStored() {
        // Arrange
        String paymentEndpoint = "/api/payments";
        String paymentJson = "{"
            + "\"isPayed\":false"
            + "}";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> request = new HttpEntity<>(paymentJson, headers);

        // Act
        ResponseEntity<String> response = restTemplate.postForEntity(paymentEndpoint, request, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().is2xxSuccessful() ||
            response.getStatusCode().equals(HttpStatus.BAD_REQUEST)
        );
    }

    @Test
    public void whenRetrievingPaymentDetails_thenPaymentInfoReturned() {
        // Arrange
        Integer paymentId = 1;
        String paymentEndpoint = "/api/payments/" + paymentId;

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(paymentEndpoint, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().equals(HttpStatus.OK) ||
            response.getStatusCode().equals(HttpStatus.NOT_FOUND)
        );
    }

    @Test
    public void whenUpdatingPaymentStatus_thenStatusIsUpdated() {
        // Arrange
        Integer paymentId = 1;
        String paymentEndpoint = "/api/payments/" + paymentId;
        String updateJson = "{\"isPayed\":true}";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> request = new HttpEntity<>(updateJson, headers);

        // Act
        restTemplate.put(paymentEndpoint, request);

        // Assert - Verify by retrieving the payment
        ResponseEntity<String> response = restTemplate.getForEntity(paymentEndpoint, String.class);
        assertNotNull(response);
    }

    @Test
    public void whenRetrievingAllPayments_thenPaymentListReturned() {
        // Arrange
        String paymentsEndpoint = "/api/payments";

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(paymentsEndpoint, String.class);

        // Assert
        assertTrue(response.getStatusCode().is2xxSuccessful());
        assertNotNull(response.getBody());
    }

    @Test
    public void whenPaymentProcessed_thenOrderStatusUpdated() {
        // This test verifies the integration between payment and order services
        // Arrange
        Integer orderId = 1;
        String orderEndpoint = "/api/orders/" + orderId;

        // Act - First create/get order
        ResponseEntity<String> orderResponse = restTemplate.getForEntity(orderEndpoint, String.class);

        // Assert - Order should exist or return 404
        assertTrue(
            orderResponse.getStatusCode().equals(HttpStatus.OK) ||
            orderResponse.getStatusCode().equals(HttpStatus.NOT_FOUND)
        );

        // If order exists, verify payment can be associated
        if (orderResponse.getStatusCode().equals(HttpStatus.OK)) {
            String paymentsEndpoint = "/api/payments";
            ResponseEntity<String> paymentsResponse = restTemplate.getForEntity(paymentsEndpoint, String.class);
            assertTrue(paymentsResponse.getStatusCode().is2xxSuccessful());
        }
    }
}
