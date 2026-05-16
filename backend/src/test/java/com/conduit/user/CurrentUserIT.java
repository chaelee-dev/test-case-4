package com.conduit.user;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.conduit.auth.JwtService;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CurrentUserIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private UserRepository userRepository;
    @Autowired private PasswordEncoder passwordEncoder;
    @Autowired private JwtService jwtService;

    private String token;

    @BeforeEach
    void seed() {
        userRepository.deleteAll();
        User u = userRepository.save(
                new User("alice", "alice@example.com", passwordEncoder.encode("secret_password")));
        token = jwtService.create(u.getId());
    }

    @Test
    void getCurrentRequiresToken() throws Exception {
        mockMvc.perform(get("/api/user")).andExpect(status().isUnauthorized());
    }

    @Test
    void getCurrentReturnsUser() throws Exception {
        mockMvc.perform(get("/api/user").header("Authorization", "Token " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.username").value("alice"))
                .andExpect(jsonPath("$.user.email").value("alice@example.com"))
                .andExpect(jsonPath("$.user.token").isNotEmpty());
    }

    @Test
    void putUpdatesBio() throws Exception {
        Map<String, Object> inner = new HashMap<>();
        inner.put("bio", "I work on dogfood");
        String body = objectMapper.writeValueAsString(Map.of("user", inner));

        mockMvc.perform(
                        put("/api/user")
                                .header("Authorization", "Token " + token)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.bio").value("I work on dogfood"));
    }

    @Test
    void putRejectsDuplicateEmail() throws Exception {
        userRepository.save(
                new User("bob", "bob@example.com", passwordEncoder.encode("other_pass")));

        String body = objectMapper.writeValueAsString(Map.of("user", Map.of("email", "bob@example.com")));

        mockMvc.perform(
                        put("/api/user")
                                .header("Authorization", "Token " + token)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.errors.email[0]").value("has already been taken"));
    }

    @Test
    void putWithoutFieldsReturns422() throws Exception {
        mockMvc.perform(
                        put("/api/user")
                                .header("Authorization", "Token " + token)
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"user\":{}}"))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void putRequiresToken() throws Exception {
        mockMvc.perform(
                        put("/api/user")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"user\":{\"bio\":\"x\"}}"))
                .andExpect(status().isUnauthorized());
    }
}
