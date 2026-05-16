package com.conduit.user.dto;

import com.conduit.user.User;

public record UserDto(String email, String token, String username, String bio, String image) {

    public static UserDto from(User user, String token) {
        return new UserDto(user.getEmail(), token, user.getUsername(), user.getBio(), user.getImage());
    }
}
