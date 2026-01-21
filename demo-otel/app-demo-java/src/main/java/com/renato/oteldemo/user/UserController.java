package com.renato.oteldemo.user;

import java.net.URI;
import java.util.List;
import java.util.Map;

import jakarta.validation.Valid;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping
    public List<User> findAll() {
        return userRepository.findAll();
    }

    @PostMapping
    public ResponseEntity<User> create(@Valid @RequestBody CreateUserRequest req) {
        if (userRepository.existsByEmail(req.email())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "email already exists");
        }

        User saved;
        try {
            saved = userRepository.save(new User(req.name(), req.email()));
        } catch (DataIntegrityViolationException e) {
            // fallback in case of race condition on unique constraint
            throw new ResponseStatusException(HttpStatus.CONFLICT, "email already exists", e);
        }

        URI location = ServletUriComponentsBuilder
                .fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(saved.getId())
                .toUri();

        return ResponseEntity.created(location).body(saved);
    }

    /**
     * Endpoint de teste: gera erro 500 para você ver spans de erro no tracing.
     */
    @GetMapping("/boom")
    public List<User> boom() {
        throw new IllegalStateException("Erro proposital em /users/boom para demonstrar rastros de erro via OTel");
    }

    /**
     * Endpoint de teste: simula um erro de banco (apenas lança uma exceção).
     */
    @GetMapping("/db-error")
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public Map<String, Object> dbError() {
        throw new RuntimeException("Simulated database error: timeout while executing SELECT on table users");
    }
}


