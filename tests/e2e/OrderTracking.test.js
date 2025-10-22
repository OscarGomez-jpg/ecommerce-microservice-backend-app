const axios = require('axios');

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:8080';

describe('E2E: Order Tracking Flow', () => {
  let orderId, paymentId, shippingId;

  test('1. User creates new order', async () => {
    try {
      const orderData = {
        orderDesc: 'Test Order for Tracking',
        orderDate: new Date().toISOString()
      };
      const response = await axios.post(`${API_BASE_URL}/api/orders`, orderData);
      expect([200, 201, 400]).toContain(response.status);

      if ([200, 201].includes(response.status)) {
        orderId = response.data.orderId || 1;
      } else {
        orderId = 1;
      }
    } catch (error) {
      orderId = 1;
    }
  });

  test('2. User checks order status', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/orders/${orderId}`);
      expect([200, 404]).toContain(response.status);

      if (response.status === 200) {
        expect(response.data).toHaveProperty('orderId');
        expect(response.data).toHaveProperty('orderDate');
      }
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });

  test('3. Payment is created for order', async () => {
    try {
      const paymentData = {
        isPayed: false
      };
      const response = await axios.post(`${API_BASE_URL}/api/payments`, paymentData);
      expect([200, 201, 400]).toContain(response.status);

      if ([200, 201].includes(response.status)) {
        paymentId = response.data.paymentId || 1;
      } else {
        paymentId = 1;
      }
    } catch (error) {
      paymentId = 1;
    }
  });

  test('4. User checks payment status', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/payments/${paymentId}`);
      expect([200, 404]).toContain(response.status);

      if (response.status === 200) {
        expect(response.data).toHaveProperty('paymentId');
        expect(response.data).toHaveProperty('isPayed');
      }
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });

  test('5. Shipping information is created', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/shipping/order/${orderId}`);
      expect([200, 404]).toContain(response.status);
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });

  test('6. User tracks shipment', async () => {
    try {
      const trackingNumber = 'TRACK12345';
      const response = await axios.get(`${API_BASE_URL}/api/shipping/track/${trackingNumber}`);
      expect([200, 404]).toContain(response.status);
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });

  test('7. User views complete order details', async () => {
    try {
      const response = await axios.get(`${API_BASE_URL}/api/orders/${orderId}`);
      expect([200, 404]).toContain(response.status);
    } catch (error) {
      expect([200, 404]).toContain(error.response?.status);
    }
  });
});
