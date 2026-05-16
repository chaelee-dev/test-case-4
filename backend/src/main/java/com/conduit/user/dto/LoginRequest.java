package com.conduit.user.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoginRequest(@Valid Wrapper user) {

    public record Wrapper(
            @NotBlank(message = "can't be blank") @Email(message = "is invalid") String email,
            @NotBlank(message = "can't be blank") String password) {}
}
