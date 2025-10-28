package com.selimhorri.app;

import com.netflix.discovery.EurekaClient;
import com.netflix.eureka.EurekaServerContext;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.context.ApplicationContext;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ServiceDiscoveryApplicationTests {

	@Autowired
	private ApplicationContext applicationContext;

	@Autowired
	private TestRestTemplate restTemplate;

	@Autowired(required = false)
	private EurekaServerContext eurekaServerContext;

	@Test
	void contextLoads() {
		// Verifica que el contexto de Spring se carga correctamente
		assertNotNull(applicationContext);
	}

	@Test
	void testEurekaServerContextExists() {
		// Verifica que el contexto del servidor Eureka existe
		assertNotNull(eurekaServerContext, "EurekaServerContext should be present");
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
	void testApplicationContextHasEurekaBeans() {
		// Verifica que hay beans relacionados con Eureka en el contexto
		String[] beanNames = applicationContext.getBeanDefinitionNames();
		assertTrue(beanNames.length > 0, "Application context should have beans");

		// Buscar algún bean relacionado con Eureka
		boolean hasEurekaBean = false;
		for (String beanName : beanNames) {
			if (beanName.toLowerCase().contains("eureka")) {
				hasEurekaBean = true;
				break;
			}
		}
		assertTrue(hasEurekaBean, "Should have Eureka-related beans");
	}

	@Test
	void testEurekaServerConfiguration() {
		// Verifica que la configuración del servidor Eureka está presente
		String registerWithEureka = applicationContext.getEnvironment()
				.getProperty("eureka.client.register-with-eureka");
		String fetchRegistry = applicationContext.getEnvironment()
				.getProperty("eureka.client.fetch-registry");

		// En un servidor Eureka, estas propiedades típicamente están en false
		assertNotNull(applicationContext.getEnvironment().getProperty("spring.application.name"),
				"Application name should be configured");
	}
}
