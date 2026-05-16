package com.conduit.user.dto;

public record UpdateUserRequest(Wrapper user) {

    public record Wrapper(String email, String username, String password, String bio, String image) {}
}
