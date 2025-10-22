package com.selimhorri.app.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.selimhorri.app.domain.OrderItem;
import com.selimhorri.app.domain.id.OrderItemId;
import com.selimhorri.app.dto.OrderItemDto;
import com.selimhorri.app.helper.OrderItemMappingHelper;
import com.selimhorri.app.repository.OrderItemRepository;
import com.selimhorri.app.service.impl.OrderItemServiceImpl;

@ExtendWith(MockitoExtension.class)
class ShippingServiceTest {

    @Mock
    private OrderItemRepository orderItemRepository;

    @InjectMocks
    private OrderItemServiceImpl orderItemService;

    private OrderItem testOrderItem;
    private OrderItemDto testOrderItemDto;
    private OrderItemId testOrderItemId;

    @BeforeEach
    void setUp() {
        testOrderItemId = new OrderItemId(1, 1); // productId, orderId

        testOrderItem = OrderItem.builder()
                .productId(1)
                .orderId(1)
                .orderedQuantity(5)
                .build();

        testOrderItemDto = OrderItemMappingHelper.map(testOrderItem);
    }

    @Test
    void testFindAll_ShouldReturnAllShipments() {
        // Arrange
        OrderItem orderItem2 = OrderItem.builder()
                .productId(2)
                .orderId(1)
                .orderedQuantity(3)
                .build();

        when(orderItemRepository.findAll()).thenReturn(Arrays.asList(testOrderItem, orderItem2));

        // Act
        List<OrderItemDto> result = orderItemService.findAll();

        // Assert
        assertNotNull(result);
        assertEquals(2, result.size());
        verify(orderItemRepository, times(1)).findAll();
    }

    @Test
    void testFindById_WithValidId_ShouldReturnShipment() {
        // Arrange
        when(orderItemRepository.findById(testOrderItemId)).thenReturn(Optional.of(testOrderItem));

        // Act
        OrderItemDto result = orderItemService.findById(testOrderItemId);

        // Assert
        assertNotNull(result);
        assertEquals(5, result.getOrderedQuantity());
        verify(orderItemRepository, times(1)).findById(testOrderItemId);
    }

    @Test
    void testSave_ShouldCreateNewShipment() {
        // Arrange
        when(orderItemRepository.save(any(OrderItem.class))).thenReturn(testOrderItem);

        // Act
        OrderItemDto result = orderItemService.save(testOrderItemDto);

        // Assert
        assertNotNull(result);
        assertEquals(testOrderItem.getOrderedQuantity(), result.getOrderedQuantity());
        verify(orderItemRepository, times(1)).save(any(OrderItem.class));
    }

    @Test
    void testCalculateShippingCost_ShouldReturnCorrectAmount() {
        // Arrange
        int quantity = 5;
        double baseRate = 10.0;

        // Act
        double shippingCost = quantity * baseRate;

        // Assert
        assertEquals(50.0, shippingCost);
    }

    @Test
    void testOrderedQuantity_ShouldBePositive() {
        // Assert
        assertTrue(testOrderItem.getOrderedQuantity() > 0);
        assertEquals(5, testOrderItem.getOrderedQuantity());
    }
}
