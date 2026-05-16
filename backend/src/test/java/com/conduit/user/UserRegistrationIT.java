package com.conduit.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
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
@AutoConfigureMockMvc(addFilters = false)
@ActiveProfiles("test")
class UserRegistrationIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private UserRepository userRepository;
    @Autowired private PasswordEncoder passwordEncoder;

    @BeforeEach
    void cleanup() {
        userRepository.deleteAll();
    }

    private String body(String username, String email, String password) throws Exception {
        return objectMapper.writeValueAsString(
                Map.of("user", Map.of("username", username, "email", email, "password", password)));
    }

    @Test
    void registerHappyPathReturns201WithToken() throws Exception {
        mockMvc.perform(
                        post("/api/users")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("alice", "alice@example.com", "secret_password")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.user.username").value("alice"))
                .andExpect(jsonPath("$.user.email").value("alice@example.com"))
                .andExpect(jsonPath("$.user.token").isNotEmpty())
                .andExpect(jsonPath("$.user.bio").doesNotExist())
                .andExpect(jsonPath("$.user.image").doesNotExist());

        var stored = userRepository.findByEmail("alice@example.com").orElseThrow();
        assertThat(stored.getPasswordHash()).startsWith("$2");
        assertThat(passwordEncoder.matches("secret_password", stored.getPasswordHash())).isTrue();
    }

    @Test
    void duplicateUsernameReturns409() throws Exception {
        userRepository.save(new User("alice", "first@example.com", passwordEncoder.encode("xxxxxxxx")));

        mockMvc.perform(
                        post("/api/users")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("alice", "second@example.com", "yyyyyyyyy")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errors.username[0]").value("has already been taken"));
    }

    @Test
    void duplicateEmailReturns409() throws Exception {
        userRepository.save(new User("alice", "shared@example.com", passwordEncoder.encode("xxxxxxxx")));

        mockMvc.perform(
                        post("/api/users")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("bob", "shared@example.com", "yyyyyyyyy")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errors.email[0]").value("has already been taken"));
    }

    @Test
    void shortPasswordReturns422() throws Exception {
        mockMvc.perform(
                        post("/api/users")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("alice", "alice@example.com", "short")))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.errors.['user.password'][0]").exists());
    }

    @Test
    void missingFieldReturns422() throws Exception {
        mockMvc.perform(
                        post("/api/users")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"user\":{\"username\":\"\",\"email\":\"\",\"password\":\"\"}}"))
                .andExpect(status().isUnprocessableEntity());
    }
}
