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

import com.selimhorri.app.domain.Product;
import com.selimhorri.app.dto.ProductDto;
import com.selimhorri.app.helper.ProductMappingHelper;
import com.selimhorri.app.repository.ProductRepository;
import com.selimhorri.app.service.impl.ProductServiceImpl;
import com.selimhorri.app.exception.wrapper.ProductNotFoundException;

@ExtendWith(MockitoExtension.class)
class ProductServiceTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private ProductServiceImpl productService;

    private Product testProduct;
    private ProductDto testProductDto;

    @BeforeEach
    void setUp() {
        testProduct = new Product();
        testProduct.setProductId(1);
        testProduct.setProductTitle("Test Product");
        testProduct.setSku("SKU001");
        testProduct.setPriceUnit(99.99);
        testProduct.setQuantity(100);

        testProductDto = ProductMappingHelper.map(testProduct);
    }

    @Test
    void testFindAll_ShouldReturnAllProducts() {
        // Arrange
        Product product2 = new Product();
        product2.setProductId(2);
        product2.setProductTitle("Product 2");
        when(productRepository.findAll()).thenReturn(Arrays.asList(testProduct, product2));

        // Act
        List<ProductDto> result = productService.findAll();

        // Assert
        assertNotNull(result);
        assertEquals(2, result.size());
        verify(productRepository, times(1)).findAll();
    }

    @Test
    void testFindById_WithValidId_ShouldReturnProduct() {
        // Arrange
        when(productRepository.findById(1)).thenReturn(Optional.of(testProduct));

        // Act
        ProductDto result = productService.findById(1);

        // Assert
        assertNotNull(result);
        assertEquals(testProduct.getProductId(), result.getProductId());
        assertEquals(testProduct.getProductTitle(), result.getProductTitle());
        verify(productRepository, times(1)).findById(1);
    }

    @Test
    void testFindById_WithInvalidId_ShouldThrowException() {
        // Arrange
        when(productRepository.findById(999)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(ProductNotFoundException.class, () -> productService.findById(999));
        verify(productRepository, times(1)).findById(999);
    }

    @Test
    void testSave_ShouldCreateNewProduct() {
        // Arrange
        when(productRepository.save(any(Product.class))).thenReturn(testProduct);

        // Act
        ProductDto result = productService.save(testProductDto);

        // Assert
        assertNotNull(result);
        assertEquals(testProduct.getProductTitle(), result.getProductTitle());
        assertEquals(testProduct.getSku(), result.getSku());
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    void testDeleteById_ShouldDeleteProduct() {
        // Arrange
        doNothing().when(productRepository).deleteById(1);

        // Act
        productService.deleteById(1);

        // Assert
        verify(productRepository, times(1)).deleteById(1);
    }

    @Test
    void testUpdate_ShouldUpdateProductPrice() {
        // Arrange
        testProductDto.setPriceUnit(149.99);
        when(productRepository.save(any(Product.class))).thenReturn(testProduct);

        // Act
        ProductDto result = productService.update(testProductDto);

        // Assert
        assertNotNull(result);
        verify(productRepository, times(1)).save(any(Product.class));
    }

    @Test
    void testSave_WithZeroQuantity_ShouldCreateProduct() {
        // Arrange
        testProduct.setQuantity(0);
        when(productRepository.save(any(Product.class))).thenReturn(testProduct);

        // Act
        ProductDto result = productService.save(testProductDto);

        // Assert
        assertNotNull(result);
        assertEquals(0, result.getQuantity());
    }
}
