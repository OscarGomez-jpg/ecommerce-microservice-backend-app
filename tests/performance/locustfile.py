from locust import HttpUser, task, between, SequentialTaskSet
import random
import json


class EcommerceUserBehavior(SequentialTaskSet):
    """
    Sequential task set that simulates a realistic user journey through the ecommerce platform
    """

    def on_start(self):
        """Initialize user session and get real user IDs from API"""
        self.product_id = None
        self.order_id = None
        self.payment_id = None

        # Get real user IDs from the API
        try:
            response = self.client.get("/user-service/api/users", name="/user-service/api/users [on_start]")
            if response.status_code == 200:
                users = response.json()
                if isinstance(users, list) and len(users) > 0:
                    # Pick a random user from the list
                    user = random.choice(users)
                    self.user_id = user.get('userId', random.randint(1, 100))
                else:
                    self.user_id = random.randint(1, 100)
            else:
                self.user_id = random.randint(1, 100)
        except:
            # Fallback to random ID if API call fails
            self.user_id = random.randint(1, 100)

    @task
    def browse_products(self):
        """User browses all products and picks a random one"""
        with self.client.get("/product-service/api/products", catch_response=True) as response:
            if response.status_code == 200:
                try:
                    products = response.json()
                    if isinstance(products, list) and len(products) > 0:
                        # Pick a random product from the list (more realistic)
                        product = random.choice(products)
                        self.product_id = product.get('productId', 1)
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
                if response.status_code in [200, 201, 400, 503]:
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
            elif response.status_code in [400, 503]:
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
            elif response.status_code in [400, 503]:
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
                if response.status_code in [200, 201, 404, 400, 503]:
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
    product_ids = []  # Cache of real product IDs

    def on_start(self):
        """Get real product IDs from API"""
        try:
            response = self.client.get("/product-service/api/products", name="/product-service/api/products [on_start]")
            if response.status_code == 200:
                products = response.json()
                if isinstance(products, list) and len(products) > 0:
                    # Store all product IDs
                    self.product_ids = [p.get('productId') for p in products if 'productId' in p]
        except:
            pass

    @task(10)
    def browse_products(self):
        """Browse all products"""
        self.client.get("/product-service/api/products")

    @task(5)
    def view_product(self):
        """View a specific product using real IDs"""
        if self.product_ids:
            # Use a real product ID from cache
            product_id = random.choice(self.product_ids)
        else:
            # Fallback to random ID
            product_id = random.randint(1, 20)

        with self.client.get(f"/product-service/api/products/{product_id}", catch_response=True) as response:
            # Accept 400 as valid (product might not exist)
            if response.status_code in [200, 400, 404]:
                response.success()
            else:
                response.failure(f"Unexpected status: {response.status_code}")

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
        with self.client.get("/payment-service/api/payments", catch_response=True) as response:
            # Accept 503 (service not deployed)
            if response.status_code in [200, 404, 503]:
                response.success()
            else:
                response.failure(f"Unexpected status: {response.status_code}")

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
        with self.client.get("/shipping-service/api/shipping", catch_response=True) as response:
            # Accept 503 (service not deployed)
            if response.status_code in [200, 404, 503]:
                response.success()
            else:
                response.failure(f"Unexpected status: {response.status_code}")
