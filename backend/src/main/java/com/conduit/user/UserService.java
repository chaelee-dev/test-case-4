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
}
