package com.conduit.user;

import com.conduit.auth.JwtService;
import com.conduit.user.dto.UserDto;
import com.conduit.web.exception.AppException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public UserService(
            UserRepository repository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.repository = repository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public UserDto register(String username, String email, String rawPassword) {
        if (repository.existsByUsername(username)) {
            throw AppException.duplicate("username", "has already been taken");
        }
        if (repository.existsByEmail(email)) {
            throw AppException.duplicate("email", "has already been taken");
        }
        User user = new User(username, email, passwordEncoder.encode(rawPassword));
        repository.save(user);
        return UserDto.from(user, jwtService.create(user.getId()));
    }

    public UserDto login(String email, String rawPassword) {
        User user =
                repository
                        .findByEmail(email)
                        .filter(u -> passwordEncoder.matches(rawPassword, u.getPasswordHash()))
                        .orElseThrow(AppException::invalidCredentials);
        return UserDto.from(user, jwtService.create(user.getId()));
    }

    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public UserDto getCurrent(long userId) {
        User user = repository.findById(userId).orElseThrow(() -> AppException.notFound("user"));
        return UserDto.from(user, jwtService.create(user.getId()));
    }

    @Transactional
    public UserDto update(
            long userId,
            String email,
            String username,
            String password,
            String bio,
            String image) {
        boolean anyField =
                email != null || username != null || password != null || bio != null || image != null;
        if (!anyField) {
            throw AppException.validation("user", "at least one field is required");
        }
        User user = repository.findById(userId).orElseThrow(() -> AppException.notFound("user"));
        if (email != null && !email.equals(user.getEmail())) {
            if (repository.existsByEmail(email)) {
                throw new AppException(
                        org.springframework.http.HttpStatus.UNPROCESSABLE_ENTITY,
                        java.util.Map.of("email", java.util.List.of("has already been taken")));
            }
            user.setEmail(email);
        }
        if (username != null && !username.equals(user.getUsername())) {
            if (repository.existsByUsername(username)) {
                throw new AppException(
                        org.springframework.http.HttpStatus.UNPROCESSABLE_ENTITY,
                        java.util.Map.of("username", java.util.List.of("has already been taken")));
            }
            user.setUsername(username);
        }
        if (password != null && !password.isBlank()) {
            user.setPasswordHash(passwordEncoder.encode(password));
        }
        if (bio != null) user.setBio(bio);
        if (image != null) user.setImage(image);
        return UserDto.from(user, jwtService.create(user.getId()));
    }
}
