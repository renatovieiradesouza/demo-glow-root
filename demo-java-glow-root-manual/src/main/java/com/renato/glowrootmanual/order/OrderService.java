package com.renato.glowrootmanual.order;

import java.math.BigDecimal;
import java.util.Random;

import org.glowroot.agent.api.Instrumentation;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final Random random = new Random();

    public OrderService(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }

    @Instrumentation.TraceEntry(
            message = "create order for customer={{0}} amount={{1}}",
            timer = "orders-create")
    @Transactional //transação de banco de dados que será capturada pelo Glowroot
    public Order createOrder(String customer, BigDecimal amount) {
        simulateExternalCall("fraud-check");
        Order order = new Order(customer, amount);
        return orderRepository.save(order);
    }

    @Instrumentation.TraceEntry(
            message = "pay order id={{0}}",
            timer = "orders-pay")
    @Transactional //transação de banco de dados que será capturada pelo Glowroot
    public Order payOrder(Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Order not found: " + id));

        simulateExternalCall("payment-gateway");

        // Simula falha intermitente de pagamento para gerar erros no Glowroot
        if (random.nextInt(5) == 0) { // ~20% de falha
            throw new IllegalStateException("Pagamento recusado pelo gateway externo");
        }

        order.markPaid();
        return orderRepository.save(order);
    }

    @Instrumentation.TraceEntry(
            message = "get order id={{0}}",
            timer = "orders-get")
    @Transactional //transação de banco de dados que será capturada pelo Glowroot(readOnly = true)
    public Order getOrder(Long id) {
        return orderRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Order not found: " + id));
    }

    @Instrumentation.TraceEntry(
            message = "simulate external call: {{0}}",
            timer = "external-call")
    private void simulateExternalCall(String system) {
        try {
            // Simula latência de chamada externa (100–300 ms)
            Thread.sleep(100 + random.nextInt(200));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}


