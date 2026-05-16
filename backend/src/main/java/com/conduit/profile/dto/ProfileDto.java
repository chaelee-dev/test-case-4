package com.conduit.profile.dto;

import com.conduit.user.User;

public record ProfileDto(String username, String bio, String image, boolean following) {

    public static ProfileDto from(User user, boolean following) {
        return new ProfileDto(user.getUsername(), user.getBio(), user.getImage(), following);
    }
}
