package com.selimhorri.app;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.context.ApplicationContext;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ApiGatewayApplicationTests {

	@Autowired
	private ApplicationContext applicationContext;

	@Autowired
	private TestRestTemplate restTemplate;

	@Autowired(required = false)
	private RouteLocator routeLocator;

	@Test
	void contextLoads() {
		// Verifica que el contexto de Spring se carga correctamente
		assertNotNull(applicationContext);
	}

	@Test
	void testRouteLocatorBeanExists() {
		// Verifica que el bean RouteLocator existe (Gateway configurado)
		assertNotNull(routeLocator, "RouteLocator bean should be present in Gateway");
	}

	@Test
	void testActuatorHealthEndpoint() {
		// Verifica que el endpoint de health del actuator responde
		ResponseEntity<String> response = restTemplate.getForEntity("/actuator/health", String.class);
		assertNotNull(response);
		assertTrue(response.getStatusCode().is2xxSuccessful() || response.getStatusCode() == HttpStatus.SERVICE_UNAVAILABLE,
				"Health endpoint should return 2xx or 503");
	}

	@Test
	void testApplicationContextHasGatewayBeans() {
		// Verifica que hay beans relacionados con Gateway en el contexto
		String[] beanNames = applicationContext.getBeanDefinitionNames();
		assertTrue(beanNames.length > 0, "Application context should have beans");

		// Buscar algún bean relacionado con Gateway
		boolean hasGatewayBean = false;
		for (String beanName : beanNames) {
			if (beanName.toLowerCase().contains("gateway") ||
			    beanName.toLowerCase().contains("route")) {
				hasGatewayBean = true;
				break;
			}
		}
		assertTrue(hasGatewayBean, "Should have Gateway-related beans");
	}

	@Test
	void testApplicationName() {
		// Verifica que el nombre de la aplicación está configurado
		String appName = applicationContext.getEnvironment().getProperty("spring.application.name");
		assertNotNull(appName, "Application name should be configured");
		assertTrue(appName.toLowerCase().contains("gateway") || appName.toLowerCase().contains("api"),
				"Application name should indicate it's a gateway");
	}
}
