package com.selimhorri.app.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.selimhorri.app.domain.Order;
import com.selimhorri.app.dto.OrderDto;
import com.selimhorri.app.helper.OrderMappingHelper;
import com.selimhorri.app.repository.OrderRepository;
import com.selimhorri.app.service.impl.OrderServiceImpl;
import com.selimhorri.app.exception.wrapper.OrderNotFoundException;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @InjectMocks
    private OrderServiceImpl orderService;

    private Order testOrder;
    private OrderDto testOrderDto;

    @BeforeEach
    void setUp() {
        testOrder = new Order();
        testOrder.setOrderId(1);
        testOrder.setOrderDate(LocalDateTime.now());
        testOrder.setOrderDesc("Test Order");

        testOrderDto = OrderMappingHelper.map(testOrder);
    }

    @Test
    void testFindAll_ShouldReturnAllOrders() {
        // Arrange
        Order order2 = new Order();
        order2.setOrderId(2);
        when(orderRepository.findAll()).thenReturn(Arrays.asList(testOrder, order2));

        // Act
        List<OrderDto> result = orderService.findAll();

        // Assert
        assertNotNull(result);
        assertEquals(2, result.size());
        verify(orderRepository, times(1)).findAll();
    }

    @Test
    void testFindById_WithValidId_ShouldReturnOrder() {
        // Arrange
        when(orderRepository.findById(1)).thenReturn(Optional.of(testOrder));

        // Act
        OrderDto result = orderService.findById(1);

        // Assert
        assertNotNull(result);
        assertEquals(testOrder.getOrderId(), result.getOrderId());
        verify(orderRepository, times(1)).findById(1);
    }

    @Test
    void testFindById_WithInvalidId_ShouldThrowException() {
        // Arrange
        when(orderRepository.findById(999)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(OrderNotFoundException.class, () -> orderService.findById(999));
    }

    @Test
    void testSave_ShouldCreateNewOrder() {
        // Arrange
        when(orderRepository.save(any(Order.class))).thenReturn(testOrder);

        // Act
        OrderDto result = orderService.save(testOrderDto);

        // Assert
        assertNotNull(result);
        assertEquals(testOrder.getOrderDesc(), result.getOrderDesc());
        verify(orderRepository, times(1)).save(any(Order.class));
    }

    @Test
    void testDeleteById_ShouldDeleteOrder() {
        // Arrange
        doNothing().when(orderRepository).deleteById(1);

        // Act
        orderService.deleteById(1);

        // Assert
        verify(orderRepository, times(1)).deleteById(1);
    }
}
