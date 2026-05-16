package com.conduit.web;

import java.util.List;
import java.util.Map;

public record ErrorResponse(Map<String, List<String>> errors) {

    public static ErrorResponse of(String field, String message) {
        return new ErrorResponse(Map.of(field, List.of(message)));
    }
}
