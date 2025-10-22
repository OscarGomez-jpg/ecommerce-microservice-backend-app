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

import com.selimhorri.app.domain.Payment;
import com.selimhorri.app.dto.PaymentDto;
import com.selimhorri.app.helper.PaymentMappingHelper;
import com.selimhorri.app.repository.PaymentRepository;
import com.selimhorri.app.service.impl.PaymentServiceImpl;
import com.selimhorri.app.exception.wrapper.PaymentNotFoundException;

@ExtendWith(MockitoExtension.class)
class PaymentServiceTest {

    @Mock
    private PaymentRepository paymentRepository;

    @InjectMocks
    private PaymentServiceImpl paymentService;

    private Payment testPayment;
    private PaymentDto testPaymentDto;

    @BeforeEach
    void setUp() {
        testPayment = new Payment();
        testPayment.setPaymentId(1);
        testPayment.setIsPayed(false);

        testPaymentDto = PaymentMappingHelper.map(testPayment);
    }

    @Test
    void testFindAll_ShouldReturnAllPayments() {
        // Arrange
        Payment payment2 = new Payment();
        payment2.setPaymentId(2);
        when(paymentRepository.findAll()).thenReturn(Arrays.asList(testPayment, payment2));

        // Act
        List<PaymentDto> result = paymentService.findAll();

        // Assert
        assertNotNull(result);
        assertEquals(2, result.size());
        verify(paymentRepository, times(1)).findAll();
    }

    @Test
    void testFindById_WithValidId_ShouldReturnPayment() {
        // Arrange
        when(paymentRepository.findById(1)).thenReturn(Optional.of(testPayment));

        // Act
        PaymentDto result = paymentService.findById(1);

        // Assert
        assertNotNull(result);
        assertEquals(testPayment.getPaymentId(), result.getPaymentId());
        assertFalse(result.getIsPayed());
        verify(paymentRepository, times(1)).findById(1);
    }

    @Test
    void testFindById_WithInvalidId_ShouldThrowException() {
        // Arrange
        when(paymentRepository.findById(999)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(PaymentNotFoundException.class, () -> paymentService.findById(999));
    }

    @Test
    void testSave_ShouldCreateNewPayment() {
        // Arrange
        when(paymentRepository.save(any(Payment.class))).thenReturn(testPayment);

        // Act
        PaymentDto result = paymentService.save(testPaymentDto);

        // Assert
        assertNotNull(result);
        assertEquals(testPayment.getIsPayed(), result.getIsPayed());
        verify(paymentRepository, times(1)).save(any(Payment.class));
    }

    @Test
    void testUpdate_ShouldMarkPaymentAsPaid() {
        // Arrange
        testPayment.setIsPayed(true);
        testPaymentDto.setIsPayed(true);
        when(paymentRepository.save(any(Payment.class))).thenReturn(testPayment);

        // Act
        PaymentDto result = paymentService.update(testPaymentDto);

        // Assert
        assertNotNull(result);
        assertTrue(result.getIsPayed());
        verify(paymentRepository, times(1)).save(any(Payment.class));
    }
}
