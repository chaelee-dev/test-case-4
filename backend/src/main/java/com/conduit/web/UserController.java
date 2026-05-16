package com.conduit.web;

import com.conduit.user.UserService;
import com.conduit.user.dto.LoginRequest;
import com.conduit.user.dto.RegisterRequest;
import com.conduit.user.dto.UserResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<UserResponse> register(@Valid @RequestBody RegisterRequest request) {
        var dto =
                userService.register(
                        request.user().username(), request.user().email(), request.user().password());
        return ResponseEntity.status(HttpStatus.CREATED).body(new UserResponse(dto));
    }

    @PostMapping("/login")
    public ResponseEntity<UserResponse> login(@Valid @RequestBody LoginRequest request) {
        var dto = userService.login(request.user().email(), request.user().password());
        return ResponseEntity.ok(new UserResponse(dto));
    }
}
