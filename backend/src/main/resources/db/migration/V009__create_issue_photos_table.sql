-- V009__create_issue_photos_table.sql
-- Description: Create issue_photos table for photo attachments
-- Author: Claude
-- Date: 2026-01-05

CREATE TABLE issue_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issue_id UUID NOT NULL REFERENCES issues(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    thumbnail_url TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_issue_photos_issue_id ON issue_photos(issue_id);

-- Insert seed photos for test issues
INSERT INTO issue_photos (id, issue_id, url, thumbnail_url, sort_order) VALUES
    (
        '550e8400-e29b-41d4-a716-446655440200',
        '550e8400-e29b-41d4-a716-446655440100',
        'http://localhost:8080/uploads/pothole-1.jpg',
        'http://localhost:8080/uploads/pothole-1-thumb.jpg',
        0
    ),
    (
        '550e8400-e29b-41d4-a716-446655440201',
        '550e8400-e29b-41d4-a716-446655440100',
        'http://localhost:8080/uploads/pothole-2.jpg',
        'http://localhost:8080/uploads/pothole-2-thumb.jpg',
        1
    ),
    (
        '550e8400-e29b-41d4-a716-446655440202',
        '550e8400-e29b-41d4-a716-446655440101',
        'http://localhost:8080/uploads/water-leak-1.jpg',
        'http://localhost:8080/uploads/water-leak-1-thumb.jpg',
        0
    ),
    (
        '550e8400-e29b-41d4-a716-446655440203',
        '550e8400-e29b-41d4-a716-446655440102',
        'http://localhost:8080/uploads/street-light-1.jpg',
        'http://localhost:8080/uploads/street-light-1-thumb.jpg',
        0
    ),
    (
        '550e8400-e29b-41d4-a716-446655440204',
        '550e8400-e29b-41d4-a716-446655440103',
        'http://localhost:8080/uploads/dumping-1.jpg',
        'http://localhost:8080/uploads/dumping-1-thumb.jpg',
        0
    ),
    (
        '550e8400-e29b-41d4-a716-446655440205',
        '550e8400-e29b-41d4-a716-446655440104',
        'http://localhost:8080/uploads/sewage-1.jpg',
        'http://localhost:8080/uploads/sewage-1-thumb.jpg',
        0
    );
