package com.conduit.user.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(@Valid Wrapper user) {

    public record Wrapper(
            @NotBlank(message = "can't be blank") String username,
            @NotBlank(message = "can't be blank") @Email(message = "is invalid") String email,
            @NotBlank(message = "can't be blank")
                    @Size(min = 8, message = "is too short (minimum is 8 characters)")
                    String password) {}
}
