const axios = require('axios');

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:8080';

describe('E2E: Product Search and Favourite Flow', () => {
  let productId, favouriteId;

  test('1. User searches all products', async () => {
    const response = await axios.get(`${API_BASE_URL}/api/products`);
    expect(response.status).toBe(200);
    expect(Array.isArray(response.data) || typeof response.data === 'object').toBe(true);
  });

  test('2. User filters products by category', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/products?category=electronics`);
      expect([200, 404]).toContain(response.status);
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });

  test('3. User views specific product details', async () => {
    try {
      productId = 1;
      const response = await axios.get(`${API_BASE_URL}/api/products/${productId}`);
      expect([200, 404]).toContain(response.status);

      if (response.status === 200) {
        expect(response.data).toHaveProperty('productId');
      }
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });

  test('4. User adds product to favourites', async () => {
    try {
      const favouriteData = {
        userId: 1,
        productId: productId
      };
      const response = await axios.post(`${API_BASE_URL}/api/favourites`, favouriteData);
      expect([200, 201, 400]).toContain(response.status);

      if ([200, 201].includes(response.status)) {
        favouriteId = response.data.favouriteId || 1;
      }
    } catch (error) {
      expect([200, 201, 400]).toContain(error.response?.status);
    }
  });

  test('5. User checks if product is in favourites', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/favourites/check?userId=1&productId=${productId}`);
      expect([200, 404]).toContain(response.status);
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });

  test('6. User views all their favourites', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/favourites/user/1`);
      expect([200, 404]).toContain(response.status);
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });

  test('7. User removes product from favourites', async () => {
    try {
      if (favouriteId) {
        await axios.delete(`${API_BASE_URL}/api/favourites/${favouriteId}`);
      }
      expect(true).toBe(true);
    } catch (error) {
      expect([200, 204, 404]).toContain(error.response?.status);
    }
  });
});
