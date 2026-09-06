-- V037__seed_member_password.sql
-- Description: give the seeded dev member (John Doe) a known password for email login.
-- Password: member123 (bcrypt, cost 10). Dev seed data only; production pods never run with this member.
UPDATE members
SET password_hash = '$2a$10$oNuOGd0qLqxQ.TyZsp6e.O5hz6.mbe6CQ/K/iw0JWpt1GjRjBoU2e',
    must_change_password = false
WHERE id = '550e8400-e29b-41d4-a716-446655440010'
  AND password_hash IS NULL;
