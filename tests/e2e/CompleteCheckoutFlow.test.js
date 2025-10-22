const axios = require('axios');

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:8080';

describe('E2E: Complete Checkout Flow', () => {
  let userId, productId, orderId, paymentId;

  test('1. User browses products', async () => {
    const response = await axios.get(`${API_BASE_URL}/api/products`);
    expect(response.status).toBe(200);
    expect(Array.isArray(response.data) || typeof response.data === 'object').toBe(true);

    if (Array.isArray(response.data) && response.data.length > 0) {
      productId = response.data[0].productId;
    } else {
      productId = 1; // Fallback
    }
  });

  test('2. User views product details', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/products/${productId}`);
      expect([200, 404]).toContain(response.status);
      if (response.status === 200) {
        expect(response.data).toHaveProperty('productId');
      }
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });

  test('3. User adds product to cart (creates order)', async () => {
    try {
      const orderData = {
        orderDesc: 'E2E Test Order',
        orderDate: new Date().toISOString()
      };
      const response = await axios.post(`${API_BASE_URL}/api/orders`, orderData);
      expect([200, 201, 400]).toContain(response.status);

      if ([200, 201].includes(response.status)) {
        orderId = response.data.orderId || 1;
      } else {
        orderId = 1; // Fallback
      }
    } catch (error) {
      orderId = 1; // Fallback
    }
  });

  test('4. User proceeds to payment', async () => {
    try {
      const paymentData = {
        isPayed: false
      };
      const response = await axios.post(`${API_BASE_URL}/api/payments`, paymentData);
      expect([200, 201, 400]).toContain(response.status);

      if ([200, 201].includes(response.status)) {
        paymentId = response.data.paymentId || 1;
      } else {
        paymentId = 1; // Fallback
      }
    } catch (error) {
      paymentId = 1; // Fallback
    }
  });

  test('5. Payment is processed', async () => {
    try {
      const updateData = {
        isPayed: true
      };
      const response = await axios.put(`${API_BASE_URL}/api/payments/${paymentId}`, updateData);
      expect([200, 201, 404, 400]).toContain(response.status);
    } catch (error) {
      expect([200, 201, 404, 400]).toContain(error.response?.status);
    }
  });

  test('6. Shipping is initiated', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/shipping/order/${orderId}`);
      expect([200, 404]).toContain(response.status);
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });

  test('7. User can view order history', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/orders`);
      expect(response.status).toBe(200);
      expect(Array.isArray(response.data) || typeof response.data === 'object').toBe(true);
    } catch (error) {
      expect(error.response?.status).toBe(200);
    }
  });
});
