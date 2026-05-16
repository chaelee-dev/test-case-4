package com.conduit.web.exception;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;

public class AppException extends RuntimeException {

    private final HttpStatus status;
    private final Map<String, List<String>> errors;

    public AppException(HttpStatus status, String field, String message) {
        super(message);
        this.status = status;
        this.errors = Map.of(field, List.of(message));
    }

    public AppException(HttpStatus status, Map<String, List<String>> errors) {
        super(errors.toString());
        this.status = status;
        this.errors = errors;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public Map<String, List<String>> getErrors() {
        return errors;
    }

    public static AppException unauthorized(String message) {
        return new AppException(HttpStatus.UNAUTHORIZED, "token", message);
    }

    public static AppException invalidCredentials() {
        return new AppException(HttpStatus.UNAUTHORIZED, "email or password", "is invalid");
    }

    public static AppException forbidden(String resource) {
        return new AppException(HttpStatus.FORBIDDEN, resource, "forbidden");
    }

    public static AppException notFound(String resource) {
        return new AppException(HttpStatus.NOT_FOUND, resource, "not found");
    }

    public static AppException duplicate(String field, String message) {
        return new AppException(HttpStatus.CONFLICT, field, message);
    }

    public static AppException validation(String field, String message) {
        return new AppException(HttpStatus.UNPROCESSABLE_ENTITY, field, message);
    }
}
