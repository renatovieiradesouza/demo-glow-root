package com.renato.glowrootdemo.user;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

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

    /**
     * Endpoint de teste que sempre lança uma exceção não tratada.
     * Gera um HTTP 500 e aparece em Glowroot como erro de aplicação.
     */
    @GetMapping("/boom")
    public List<User> boom() {
        throw new IllegalStateException("Erro proposital em /users/boom para demonstrar rastros de erro no Glowroot");
    }

    /**
     * Endpoint de teste que simula um erro de banco (sem realmente quebrar o schema).
     * Apenas lança uma exceção com mensagem de SQL – útil para ver o fluxo completo de erro.
     */
    @GetMapping("/db-error")
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public Map<String, Object> dbError() {
        throw new RuntimeException("Simulated database error: timeout while executing SELECT on table users");
    }
}


