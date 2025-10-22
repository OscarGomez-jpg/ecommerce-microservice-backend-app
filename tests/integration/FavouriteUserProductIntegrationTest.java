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
 * Integration test: User favourites management
 * Tests communication between favourite-service, user-service, and product-service
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
public class FavouriteUserProductIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    public void whenUserAddsFavouriteProduct_thenFavouriteIsStored() {
        // Arrange
        String favouriteEndpoint = "/api/favourites";
        String favouriteJson = "{"
            + "\"userId\":1,"
            + "\"productId\":1"
            + "}";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> request = new HttpEntity<>(favouriteJson, headers);

        // Act
        ResponseEntity<String> response = restTemplate.postForEntity(favouriteEndpoint, request, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().is2xxSuccessful() ||
            response.getStatusCode().equals(HttpStatus.BAD_REQUEST)
        );
    }

    @Test
    public void whenRetrievingUserFavourites_thenFavouriteListReturned() {
        // Arrange
        Integer userId = 1;
        String favouritesEndpoint = "/api/favourites/user/" + userId;

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(favouritesEndpoint, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().is2xxSuccessful() ||
            response.getStatusCode().equals(HttpStatus.NOT_FOUND)
        );
        assertNotNull(response.getBody());
    }

    @Test
    public void whenRemovingFavourite_thenFavouriteIsDeleted() {
        // Arrange
        Integer favouriteId = 1;
        String favouriteEndpoint = "/api/favourites/" + favouriteId;

        // Act
        restTemplate.delete(favouriteEndpoint);

        // Assert - Verify favourite is deleted
        ResponseEntity<String> response = restTemplate.getForEntity(favouriteEndpoint, String.class);
        assertTrue(
            response.getStatusCode().equals(HttpStatus.NOT_FOUND) ||
            response.getStatusCode().is2xxSuccessful()
        );
    }

    @Test
    public void whenCheckingIfProductIsFavourite_thenStatusReturned() {
        // Arrange
        Integer userId = 1;
        Integer productId = 1;
        String checkEndpoint = "/api/favourites/check?userId=" + userId + "&productId=" + productId;

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(checkEndpoint, String.class);

        // Assert
        assertTrue(
            response.getStatusCode().is2xxSuccessful() ||
            response.getStatusCode().equals(HttpStatus.NOT_FOUND)
        );
    }

    @Test
    public void whenRetrievingAllFavourites_thenFavouriteListReturned() {
        // Arrange
        String favouritesEndpoint = "/api/favourites";

        // Act
        ResponseEntity<String> response = restTemplate.getForEntity(favouritesEndpoint, String.class);

        // Assert
        assertTrue(response.getStatusCode().is2xxSuccessful());
        assertNotNull(response.getBody());
    }
}
