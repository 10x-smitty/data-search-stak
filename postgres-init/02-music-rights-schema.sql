-- Music Publishing Rights Database Schema
-- This schema represents a typical music rights management system

-- Drop existing tables if they exist
DROP TABLE IF EXISTS song_writers CASCADE;
DROP TABLE IF EXISTS song_publishers CASCADE;
DROP TABLE IF EXISTS performance_rights CASCADE;
DROP TABLE IF EXISTS mechanical_rights CASCADE;
DROP TABLE IF EXISTS songs CASCADE;
DROP TABLE IF EXISTS writers CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;

-- Writers table (songwriters, composers, lyricists)
CREATE TABLE writers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    ipi_number VARCHAR(20), -- International Standard Name Identifier
    cae_number VARCHAR(20), -- Composer, Author and Publisher number
    birth_date DATE,
    nationality VARCHAR(100),
    pro_affiliation VARCHAR(50), -- Performance Rights Organization (ASCAP, BMI, SESAC)
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Publishers table (music publishing companies)
CREATE TABLE publishers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    ipi_number VARCHAR(20),
    tax_id VARCHAR(50),
    contact_person VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    country VARCHAR(100),
    pro_affiliation VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Songs table (musical compositions)
CREATE TABLE songs (
    id SERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    alternate_titles TEXT[], -- Array of alternate titles
    iswc VARCHAR(20), -- International Standard Musical Work Code
    duration_seconds INTEGER,
    genre VARCHAR(100),
    language VARCHAR(50),
    creation_date DATE,
    registration_date DATE,
    copyright_status VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Song-Writer relationship (many-to-many with role and percentage)
CREATE TABLE song_writers (
    id SERIAL PRIMARY KEY,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    writer_id INTEGER REFERENCES writers(id) ON DELETE CASCADE,
    role VARCHAR(100), -- Composer, Lyricist, Arranger, etc.
    ownership_percentage DECIMAL(5,2), -- 0.00 to 100.00
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(song_id, writer_id, role)
);

-- Song-Publisher relationship (many-to-many with percentage)
CREATE TABLE song_publishers (
    id SERIAL PRIMARY KEY,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    publisher_id INTEGER REFERENCES publishers(id) ON DELETE CASCADE,
    ownership_percentage DECIMAL(5,2), -- 0.00 to 100.00
    territory VARCHAR(100) DEFAULT 'Worldwide',
    rights_type VARCHAR(100), -- Mechanical, Performance, Synchronization, etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(song_id, publisher_id, rights_type, territory)
);

-- Performance rights tracking (radio, streaming, live performances)
CREATE TABLE performance_rights (
    id SERIAL PRIMARY KEY,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    pro_source VARCHAR(50), -- ASCAP, BMI, SESAC, etc.
    performance_date DATE,
    venue_name VARCHAR(255),
    performer VARCHAR(255),
    usage_type VARCHAR(100), -- Radio, Streaming, Live, TV, etc.
    revenue_amount DECIMAL(10,2),
    currency VARCHAR(10) DEFAULT 'USD',
    territory VARCHAR(100) DEFAULT 'US',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Mechanical rights tracking (physical sales, downloads)
CREATE TABLE mechanical_rights (
    id SERIAL PRIMARY KEY,
    song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
    label_name VARCHAR(255),
    artist_name VARCHAR(255),
    album_title VARCHAR(255),
    release_date DATE,
    units_sold INTEGER,
    rate_per_unit DECIMAL(10,4),
    revenue_amount DECIMAL(10,2),
    currency VARCHAR(10) DEFAULT 'USD',
    territory VARCHAR(100) DEFAULT 'US',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for better performance
CREATE INDEX idx_writers_name ON writers(name);
CREATE INDEX idx_writers_ipi ON writers(ipi_number);
CREATE INDEX idx_writers_pro ON writers(pro_affiliation);
CREATE INDEX idx_publishers_name ON publishers(name);
CREATE INDEX idx_publishers_ipi ON publishers(ipi_number);
CREATE INDEX idx_songs_title ON songs(title);
CREATE INDEX idx_songs_iswc ON songs(iswc);
CREATE INDEX idx_song_writers_song_id ON song_writers(song_id);
CREATE INDEX idx_song_writers_writer_id ON song_writers(writer_id);
CREATE INDEX idx_song_publishers_song_id ON song_publishers(song_id);
CREATE INDEX idx_performance_rights_song_id ON performance_rights(song_id);
CREATE INDEX idx_performance_rights_pro ON performance_rights(pro_source);
CREATE INDEX idx_mechanical_rights_song_id ON mechanical_rights(song_id);

-- Create a view for comprehensive song information (useful for reconciliation)
CREATE VIEW songs_complete AS
SELECT 
    s.id,
    s.title,
    s.alternate_titles,
    s.iswc,
    s.genre,
    s.creation_date,
    -- Writers information (concatenated)
    STRING_AGG(DISTINCT w.name || COALESCE(' (IPI: ' || w.ipi_number || ')', ''), ', ') AS writers,
    STRING_AGG(DISTINCT w.pro_affiliation, ', ') AS writer_pros,
    -- Publishers information (concatenated)
    STRING_AGG(DISTINCT p.name || COALESCE(' (IPI: ' || p.ipi_number || ')', ''), ', ') AS publishers,
    -- Revenue information
    COALESCE(SUM(pr.revenue_amount), 0) AS total_performance_revenue,
    COALESCE(SUM(mr.revenue_amount), 0) AS total_mechanical_revenue,
    s.created_at,
    s.updated_at
FROM songs s
LEFT JOIN song_writers sw ON s.id = sw.song_id
LEFT JOIN writers w ON sw.writer_id = w.id
LEFT JOIN song_publishers sp ON s.id = sp.song_id
LEFT JOIN publishers p ON sp.publisher_id = p.id
LEFT JOIN performance_rights pr ON s.id = pr.song_id
LEFT JOIN mechanical_rights mr ON s.id = mr.song_id
GROUP BY s.id, s.title, s.alternate_titles, s.iswc, s.genre, s.creation_date, s.created_at, s.updated_at;
