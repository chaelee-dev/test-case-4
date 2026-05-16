package com.conduit.web;

import com.conduit.profile.ProfileService;
import com.conduit.profile.dto.ProfileResponse;
import com.conduit.web.exception.AppException;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/profiles")
public class ProfileController {

    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping("/{username}")
    public ResponseEntity<ProfileResponse> getProfile(
            @PathVariable String username, @AuthenticationPrincipal Long viewerId) {
        return ResponseEntity.ok(new ProfileResponse(profileService.getProfile(username, viewerId)));
    }

    @PostMapping("/{username}/follow")
    public ResponseEntity<ProfileResponse> follow(
            @PathVariable String username, @AuthenticationPrincipal Long viewerId) {
        if (viewerId == null) throw AppException.unauthorized("is invalid");
        return ResponseEntity.ok(new ProfileResponse(profileService.follow(viewerId, username)));
    }

    @DeleteMapping("/{username}/follow")
    public ResponseEntity<ProfileResponse> unfollow(
            @PathVariable String username, @AuthenticationPrincipal Long viewerId) {
        if (viewerId == null) throw AppException.unauthorized("is invalid");
        return ResponseEntity.ok(new ProfileResponse(profileService.unfollow(viewerId, username)));
    }
}
