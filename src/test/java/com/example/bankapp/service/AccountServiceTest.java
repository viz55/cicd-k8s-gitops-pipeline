package com.example.bankapp.service;

import com.example.bankapp.model.Account;
import com.example.bankapp.model.Transaction;
import com.example.bankapp.repository.AccountRepository;
import com.example.bankapp.repository.TransactionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Real behavioral tests for the core banking logic, replacing the
 * placeholder tests that shipped with the original tutorial template
 * (which only asserted 40 + 2 == 42 and did not exercise this class
 * at all). These tests give SonarQube's quality gate something
 * meaningful to measure and are worth being able to walk through in
 * an interview.
 */
@ExtendWith(MockitoExtension.class)
class AccountServiceTest {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private AccountService accountService;

    private Account account;

    @BeforeEach
    void setUp() {
        account = new Account();
        account.setId(1L);
        account.setUsername("alice");
        account.setPassword("encoded-password");
        account.setBalance(new BigDecimal("100.00"));
    }

    @Test
    void deposit_increasesBalance_andRecordsTransaction() {
        when(accountRepository.save(any(Account.class))).thenReturn(account);

        accountService.deposit(account, new BigDecimal("50.00"));

        assertEquals(new BigDecimal("150.00"), account.getBalance());
        verify(accountRepository).save(account);
        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void withdraw_decreasesBalance_whenSufficientFunds() {
        when(accountRepository.save(any(Account.class))).thenReturn(account);

        accountService.withdraw(account, new BigDecimal("30.00"));

        assertEquals(new BigDecimal("70.00"), account.getBalance());
        verify(transactionRepository).save(any(Transaction.class));
    }

    @Test
    void withdraw_throws_whenInsufficientFunds() {
        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> accountService.withdraw(account, new BigDecimal("500.00")));

        assertEquals("Insufficient funds", ex.getMessage());
        // balance must be unchanged, and nothing should have been persisted
        assertEquals(new BigDecimal("100.00"), account.getBalance());
        verify(accountRepository, never()).save(any(Account.class));
        verify(transactionRepository, never()).save(any(Transaction.class));
    }

    @Test
    void registerAccount_throws_whenUsernameAlreadyExists() {
        when(accountRepository.findByUsername("alice")).thenReturn(Optional.of(account));

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> accountService.registerAccount("alice", "password123"));

        assertEquals("Username already exists", ex.getMessage());
        verify(accountRepository, never()).save(any(Account.class));
    }

    @Test
    void registerAccount_startsWithZeroBalance_andEncodesPassword() {
        when(accountRepository.findByUsername("bob")).thenReturn(Optional.empty());
        when(passwordEncoder.encode("password123")).thenReturn("hashed");
        when(accountRepository.save(any(Account.class))).thenAnswer(inv -> inv.getArgument(0));

        Account created = accountService.registerAccount("bob", "password123");

        assertEquals(BigDecimal.ZERO, created.getBalance());
        assertEquals("hashed", created.getPassword());
        // the raw password must never be what gets persisted
        assertNotEquals("password123", created.getPassword());
    }

    @Test
    void transferAmount_movesFundsBetweenAccounts() {
        Account recipient = new Account();
        recipient.setId(2L);
        recipient.setUsername("bob");
        recipient.setBalance(new BigDecimal("20.00"));

        when(accountRepository.findByUsername("bob")).thenReturn(Optional.of(recipient));
        when(accountRepository.save(any(Account.class))).thenAnswer(inv -> inv.getArgument(0));

        accountService.transferAmount(account, "bob", new BigDecimal("40.00"));

        assertEquals(new BigDecimal("60.00"), account.getBalance());
        assertEquals(new BigDecimal("60.00"), recipient.getBalance());
        // one debit + one credit transaction recorded
        verify(transactionRepository, times(2)).save(any(Transaction.class));
    }

    @Test
    void transferAmount_throws_whenInsufficientFunds() {
        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> accountService.transferAmount(account, "bob", new BigDecimal("500.00")));

        assertEquals("Insufficient funds", ex.getMessage());
        verify(accountRepository, never()).findByUsername("bob");
    }

    @Test
    void transferAmount_throws_whenRecipientDoesNotExist() {
        when(accountRepository.findByUsername("ghost")).thenReturn(Optional.empty());

        RuntimeException ex = assertThrows(RuntimeException.class,
                () -> accountService.transferAmount(account, "ghost", new BigDecimal("10.00")));

        assertEquals("Recipient account not found", ex.getMessage());
    }

    @Test
    void findAccountByUsername_throws_whenNotFound() {
        when(accountRepository.findByUsername("nobody")).thenReturn(Optional.empty());

        assertThrows(RuntimeException.class,
                () -> accountService.findAccountByUsername("nobody"));
    }
}
