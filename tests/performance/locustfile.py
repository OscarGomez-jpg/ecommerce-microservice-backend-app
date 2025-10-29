from locust import HttpUser, task, between, SequentialTaskSet
import random
import json


class EcommerceUserBehavior(SequentialTaskSet):
    """
    Sequential task set that simulates a realistic user journey through the ecommerce platform
    """

    def on_start(self):
        """Initialize user session"""
        self.product_id = None
        self.order_id = None
        self.payment_id = None
        self.user_id = random.randint(1, 100)

    @task
    def browse_products(self):
        """User browses all products"""
        with self.client.get("/product-service/api/products", catch_response=True) as response:
            if response.status_code == 200:
                try:
                    products = response.json()
                    if isinstance(products, list) and len(products) > 0:
                        self.product_id = products[0].get('productId', 1)
                    else:
                        self.product_id = 1
                    response.success()
                except:
                    self.product_id = 1
                    response.success()
            else:
                response.failure(f"Failed to get products: {response.status_code}")

    @task
    def view_product_details(self):
        """User views details of a specific product"""
        if self.product_id:
            with self.client.get(f"/product-service/api/products/{self.product_id}", catch_response=True) as response:
                if response.status_code in [200, 404]:
                    response.success()
                else:
                    response.failure(f"Failed to get product details: {response.status_code}")

    @task
    def add_to_favourites(self):
        """User adds product to favourites"""
        if self.product_id:
            payload = {
                "userId": self.user_id,
                "productId": self.product_id
            }
            with self.client.post("/favourite-service/api/favourites",
                                 json=payload,
                                 catch_response=True) as response:
                if response.status_code in [200, 201, 400]:
                    response.success()
                else:
                    response.failure(f"Failed to add favourite: {response.status_code}")

    @task
    def create_order(self):
        """User creates an order"""
        payload = {
            "orderDesc": f"Locust test order {random.randint(1, 10000)}",
            "orderDate": "2024-01-15T10:30:00"
        }
        with self.client.post("/order-service/api/orders",
                             json=payload,
                             catch_response=True) as response:
            if response.status_code in [200, 201]:
                try:
                    order = response.json()
                    self.order_id = order.get('orderId', 1)
                    response.success()
                except:
                    self.order_id = 1
                    response.success()
            elif response.status_code == 400:
                self.order_id = 1
                response.success()
            else:
                self.order_id = 1
                response.failure(f"Failed to create order: {response.status_code}")

    @task
    def process_payment(self):
        """User processes payment for order"""
        payload = {
            "isPayed": False
        }
        with self.client.post("/payment-service/api/payments",
                             json=payload,
                             catch_response=True) as response:
            if response.status_code in [200, 201]:
                try:
                    payment = response.json()
                    self.payment_id = payment.get('paymentId', 1)
                    response.success()
                except:
                    self.payment_id = 1
                    response.success()
            elif response.status_code == 400:
                self.payment_id = 1
                response.success()
            else:
                self.payment_id = 1
                response.failure(f"Failed to process payment: {response.status_code}")

    @task
    def complete_payment(self):
        """User completes the payment"""
        if self.payment_id:
            payload = {
                "isPayed": True
            }
            with self.client.put(f"/payment-service/api/payments/{self.payment_id}",
                                json=payload,
                                catch_response=True) as response:
                if response.status_code in [200, 201, 404, 400]:
                    response.success()
                else:
                    response.failure(f"Failed to complete payment: {response.status_code}")

    @task
    def check_order_status(self):
        """User checks order status"""
        if self.order_id:
            with self.client.get(f"/order-service/api/orders/{self.order_id}", catch_response=True) as response:
                if response.status_code in [200, 404]:
                    response.success()
                else:
                    response.failure(f"Failed to check order status: {response.status_code}")


class BrowsingUser(HttpUser):
    """
    User that primarily browses products and views details
    """
    wait_time = between(1, 3)
    weight = 3

    @task(10)
    def browse_products(self):
        """Browse all products"""
        self.client.get("/product-service/api/products")

    @task(5)
    def view_product(self):
        """View a specific product"""
        product_id = random.randint(1, 20)
        self.client.get(f"/product-service/api/products/{product_id}")

    @task(2)
    def view_categories(self):
        """Browse products by category"""
        self.client.get("/product-service/api/products?category=electronics")


class PurchasingUser(HttpUser):
    """
    User that completes full purchase flows
    """
    wait_time = between(2, 5)
    weight = 2
    tasks = [EcommerceUserBehavior]


class AdminUser(HttpUser):
    """
    Admin user that manages orders and products
    """
    wait_time = between(3, 7)
    weight = 1

    @task(5)
    def view_all_orders(self):
        """Admin views all orders"""
        self.client.get("/order-service/api/orders")

    @task(3)
    def view_all_payments(self):
        """Admin views all payments"""
        self.client.get("/payment-service/api/payments")

    @task(2)
    def view_all_users(self):
        """Admin views all users"""
        self.client.get("/user-service/api/users")

    @task(4)
    def view_all_products(self):
        """Admin views all products"""
        self.client.get("/product-service/api/products")

    @task(1)
    def view_shipping(self):
        """Admin views shipping information"""
        self.client.get("/shipping-service/api/shipping")
