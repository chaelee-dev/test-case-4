package com.conduit.user;

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
class LoginIT {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private UserRepository userRepository;
    @Autowired private PasswordEncoder passwordEncoder;

    @BeforeEach
    void seed() {
        userRepository.deleteAll();
        userRepository.save(
                new User("alice", "alice@example.com", passwordEncoder.encode("correct_password")));
    }

    private String body(String email, String password) throws Exception {
        return objectMapper.writeValueAsString(Map.of("user", Map.of("email", email, "password", password)));
    }

    @Test
    void loginHappyPathReturns200WithToken() throws Exception {
        mockMvc.perform(
                        post("/api/users/login")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("alice@example.com", "correct_password")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.email").value("alice@example.com"))
                .andExpect(jsonPath("$.user.username").value("alice"))
                .andExpect(jsonPath("$.user.token").isNotEmpty());
    }

    @Test
    void wrongPasswordReturns401() throws Exception {
        mockMvc.perform(
                        post("/api/users/login")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("alice@example.com", "wrong_password")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errors.['email or password'][0]").value("is invalid"));
    }

    @Test
    void unknownEmailReturns401() throws Exception {
        mockMvc.perform(
                        post("/api/users/login")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(body("nobody@example.com", "correct_password")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errors.['email or password'][0]").value("is invalid"));
    }

    @Test
    void missingFieldReturns422() throws Exception {
        mockMvc.perform(
                        post("/api/users/login")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content("{\"user\":{\"email\":\"\",\"password\":\"\"}}"))
                .andExpect(status().isUnprocessableEntity());
    }
}
