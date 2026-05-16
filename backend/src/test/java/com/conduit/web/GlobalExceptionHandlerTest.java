package com.conduit.web;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.conduit.web.exception.AppException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.stereotype.Component;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootTest
@AutoConfigureMockMvc(addFilters = false)
@ActiveProfiles("test")
@Import(GlobalExceptionHandlerTest.ProbeController.class)
class GlobalExceptionHandlerTest {

    @Autowired private MockMvc mockMvc;

    @Component
    @RestController
    public static class ProbeController {
        @GetMapping("/test/unauthorized")
        public String unauthorized() {
            throw AppException.unauthorized("is invalid");
        }

        @GetMapping("/test/credentials")
        public String credentials() {
            throw AppException.invalidCredentials();
        }

        @GetMapping("/test/forbidden")
        public String forbidden() {
            throw AppException.forbidden("article");
        }

        @GetMapping("/test/notfound")
        public String notFound() {
            throw AppException.notFound("user");
        }

        @GetMapping("/test/duplicate")
        public String duplicate() {
            throw AppException.duplicate("email", "has already been taken");
        }

        @GetMapping("/test/validation")
        public String validation() {
            throw AppException.validation("title", "can't be blank");
        }

        @GetMapping("/test/oops")
        public String oops() {
            throw new RuntimeException("boom");
        }
    }

    @Test
    void unauthorizedReturns401Wrapped() throws Exception {
        mockMvc.perform(get("/test/unauthorized"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errors.token[0]").value("is invalid"));
    }

    @Test
    void credentialsReturns401WrappedWithCompoundField() throws Exception {
        mockMvc.perform(get("/test/credentials"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.errors['email or password'][0]").value("is invalid"));
    }

    @Test
    void forbiddenReturns403WithResourceKey() throws Exception {
        mockMvc.perform(get("/test/forbidden"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.errors.article[0]").value("forbidden"));
    }

    @Test
    void notFoundReturns404WithResourceKey() throws Exception {
        mockMvc.perform(get("/test/notfound"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errors.user[0]").value("not found"));
    }

    @Test
    void duplicateReturns409() throws Exception {
        mockMvc.perform(get("/test/duplicate"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.errors.email[0]").value("has already been taken"));
    }

    @Test
    void validationReturns422() throws Exception {
        mockMvc.perform(get("/test/validation"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.errors.title[0]").value("can't be blank"));
    }

    @Test
    void unhandledExceptionReturns500WrappedAsServerInternalError() throws Exception {
        mockMvc.perform(get("/test/oops"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.errors.server[0]").value("internal error"));
    }
}
