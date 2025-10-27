package com.selimhorri.app.helper;

import java.util.Collections;
import java.util.stream.Collectors;

import com.selimhorri.app.domain.Address;
import com.selimhorri.app.domain.Credential;
import com.selimhorri.app.domain.User;
import com.selimhorri.app.dto.AddressDto;
import com.selimhorri.app.dto.CredentialDto;
import com.selimhorri.app.dto.UserDto;

public interface UserMappingHelper {
	
	public static UserDto map(final User user) {
		return UserDto.builder()
				.userId(user.getUserId())
				.firstName(user.getFirstName())
				.lastName(user.getLastName())
				.imageUrl(user.getImageUrl())
				.email(user.getEmail())
				.phone(user.getPhone())
				.addressDtos(
						user.getAddresses() != null && !user.getAddresses().isEmpty()
							? user.getAddresses().stream()
								.map(address -> AddressDto.builder()
										.addressId(address.getAddressId())
										.fullAddress(address.getFullAddress())
										.postalCode(address.getPostalCode())
										.city(address.getCity())
										.build())
								.collect(Collectors.toSet())
							: Collections.emptySet())
				.credentialDto(
						user.getCredential() != null
							? CredentialDto.builder()
								.credentialId(user.getCredential().getCredentialId())
								.username(user.getCredential().getUsername())
								.password(user.getCredential().getPassword())
								.roleBasedAuthority(user.getCredential().getRoleBasedAuthority())
								.isEnabled(user.getCredential().getIsEnabled())
								.isAccountNonExpired(user.getCredential().getIsAccountNonExpired())
								.isAccountNonLocked(user.getCredential().getIsAccountNonLocked())
								.isCredentialsNonExpired(user.getCredential().getIsCredentialsNonExpired())
								.build()
							: null)
				.build();
	}
	
	public static User map(final UserDto userDto) {
		return User.builder()
				.userId(userDto.getUserId())
				.firstName(userDto.getFirstName())
				.lastName(userDto.getLastName())
				.imageUrl(userDto.getImageUrl())
				.email(userDto.getEmail())
				.phone(userDto.getPhone())
				.addresses(
						userDto.getAddressDtos() != null && !userDto.getAddressDtos().isEmpty()
							? userDto.getAddressDtos().stream()
								.map(addressDto -> Address.builder()
										.addressId(addressDto.getAddressId())
										.fullAddress(addressDto.getFullAddress())
										.postalCode(addressDto.getPostalCode())
										.city(addressDto.getCity())
										.build())
								.collect(Collectors.toSet())
							: Collections.emptySet())
				.credential(
						userDto.getCredentialDto() != null
							? Credential.builder()
								.credentialId(userDto.getCredentialDto().getCredentialId())
								.username(userDto.getCredentialDto().getUsername())
								.password(userDto.getCredentialDto().getPassword())
								.roleBasedAuthority(userDto.getCredentialDto().getRoleBasedAuthority())
								.isEnabled(userDto.getCredentialDto().getIsEnabled())
								.isAccountNonExpired(userDto.getCredentialDto().getIsAccountNonExpired())
								.isAccountNonLocked(userDto.getCredentialDto().getIsAccountNonLocked())
								.isCredentialsNonExpired(userDto.getCredentialDto().getIsCredentialsNonExpired())
								.build()
							: null)
				.build();
	}
	
	
	
}






