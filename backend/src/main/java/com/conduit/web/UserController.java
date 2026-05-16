package com.conduit.web;

import com.conduit.user.UserService;
import com.conduit.user.dto.LoginRequest;
import com.conduit.user.dto.RegisterRequest;
import com.conduit.user.dto.UpdateUserRequest;
import com.conduit.user.dto.UserResponse;
import com.conduit.web.exception.AppException;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping("/api/users")
    public ResponseEntity<UserResponse> register(@Valid @RequestBody RegisterRequest request) {
        var dto =
                userService.register(
                        request.user().username(), request.user().email(), request.user().password());
        return ResponseEntity.status(HttpStatus.CREATED).body(new UserResponse(dto));
    }

    @PostMapping("/api/users/login")
    public ResponseEntity<UserResponse> login(@Valid @RequestBody LoginRequest request) {
        var dto = userService.login(request.user().email(), request.user().password());
        return ResponseEntity.ok(new UserResponse(dto));
    }

    @GetMapping("/api/user")
    public ResponseEntity<UserResponse> getCurrent(@AuthenticationPrincipal Long userId) {
        if (userId == null) {
            throw AppException.unauthorized("is invalid");
        }
        return ResponseEntity.ok(new UserResponse(userService.getCurrent(userId)));
    }

    @PutMapping("/api/user")
    public ResponseEntity<UserResponse> updateCurrent(
            @AuthenticationPrincipal Long userId, @RequestBody UpdateUserRequest request) {
        if (userId == null) {
            throw AppException.unauthorized("is invalid");
        }
        var u = request.user();
        if (u == null) {
            throw AppException.validation("user", "at least one field is required");
        }
        var dto = userService.update(userId, u.email(), u.username(), u.password(), u.bio(), u.image());
        return ResponseEntity.ok(new UserResponse(dto));
    }
}
