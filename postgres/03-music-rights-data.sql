-- Mock Music Rights Data
-- This provides realistic test data for music rights reconciliation

-- Insert Writers
INSERT INTO writers (name, ipi_number, cae_number, birth_date, nationality, pro_affiliation, email, phone) VALUES
('John Lennon', '00014107338', 'IPI14107338', '1940-10-09', 'British', 'PRS', 'john@beatles.com', '+44-20-7946-0958'),
('Paul McCartney', '00026239279', 'IPI26239279', '1942-06-18', 'British', 'PRS', 'paul@mccartney.com', '+44-20-7946-0959'),
('Diane Warren', '00145380046', 'IPI145380046', '1956-09-07', 'American', 'ASCAP', 'diane@warren.com', '+1-310-555-0123'),
('Max Martin', '00500019958', 'IPI500019958', '1971-02-26', 'Swedish', 'STIM', 'max@martinsongs.com', '+46-8-555-0124'),
('Taylor Swift', '00450016959', 'IPI450016959', '1989-12-13', 'American', 'ASCAP', 'taylor@swift.com', '+1-615-555-0125'),
('Ed Sheeran', '00490019456', 'IPI490019456', '1991-02-17', 'British', 'PRS', 'ed@sheeran.com', '+44-20-7946-0960'),
('Bruno Mars', '00510020789', 'IPI510020789', '1985-10-08', 'American', 'BMI', 'bruno@mars.com', '+1-310-555-0126'),
('Adele Adkins', '00470018234', 'IPI470018234', '1988-05-05', 'British', 'PRS', 'adele@adele.com', '+44-20-7946-0961'),
('The Weeknd', '00530022456', 'IPI530022456', '1990-02-16', 'Canadian', 'SOCAN', 'weeknd@xo.com', '+1-416-555-0127'),
('Beyonce Knowles', '00440015678', 'IPI440015678', '1981-09-04', 'American', 'ASCAP', 'beyonce@parkwood.com', '+1-212-555-0128');

-- Insert Publishers
INSERT INTO publishers (name, ipi_number, tax_id, contact_person, email, phone, country, pro_affiliation) VALUES
('Sony/ATV Music Publishing', '00026955529', 'US-12345678', 'Jon Platt', 'contact@sonyatv.com', '+1-615-321-8000', 'United States', 'ASCAP'),
('Universal Music Publishing', '00138635135', 'US-12345679', 'Jody Gerson', 'contact@umpg.com', '+1-310-235-4700', 'United States', 'BMI'),
('Warner Chappell Music', '00052063512', 'US-12345680', 'Guy Moot', 'contact@warnerchappell.com', '+1-818-954-6000', 'United States', 'ASCAP'),
('BMG Rights Management', '00234567890', 'US-12345681', 'Thomas Coesfeld', 'contact@bmg.com', '+49-30-2425-9000', 'Germany', 'GEMA'),
('Kobalt Music Publishing', '00345678901', 'US-12345682', 'Laurent Hubert', 'contact@kobalt.com', '+1-212-247-6500', 'United States', 'ASCAP'),
('Big Machine Music', '00456789012', 'US-12345683', 'Scott Borchetta', 'contact@bigmachine.com', '+1-615-321-8888', 'United States', 'BMI'),
('Taylor Swift Music', '00567890123', 'US-12345684', 'Taylor Swift', 'business@taylorswift.com', '+1-615-555-0129', 'United States', 'ASCAP'),
('XO Music Publishing', '00678901234', 'CA-12345685', 'The Weeknd', 'business@xo.com', '+1-416-555-0130', 'Canada', 'SOCAN'),
('Parkwood Entertainment', '00789012345', 'US-12345686', 'Beyonce Knowles', 'business@parkwood.com', '+1-212-555-0131', 'United States', 'ASCAP'),
('Atlantic Records Music', '00890123456', 'US-12345687', 'Craig Kallman', 'contact@atlantic.com', '+1-212-707-2000', 'United States', 'BMI');

-- Insert Songs
INSERT INTO songs (title, alternate_titles, iswc, duration_seconds, genre, language, creation_date, registration_date, copyright_status) VALUES
('Hey Jude', '{"Hey Jude (Remastered)", "Hey Jude - 2018 Mix"}', 'T-070.246.800-1', 431, 'Rock', 'English', '1968-07-29', '1968-08-26', 'Active'),
('Yesterday', '{"Yesterday (Remastered)", "Yesterday - Love Version"}', 'T-070.246.801-2', 125, 'Pop', 'English', '1965-06-14', '1965-09-13', 'Active'),
('I Dont Want to Miss a Thing', '{"I Don''t Want to Miss a Thing", "I Do not Want to Miss a Thing"}', 'T-101.234.567-1', 299, 'Rock Ballad', 'English', '1998-05-12', '1998-07-01', 'Active'),
('...Baby One More Time', '{"Baby One More Time", "...Baby 1 More Time"}', 'T-201.345.678-2', 211, 'Pop', 'English', '1998-10-23', '1999-01-12', 'Active'),
('Shake It Off', '{"Shake It Off (Taylor''s Version)", "Shake It Off - Radio Edit"}', 'T-301.456.789-3', 219, 'Pop', 'English', '2014-08-18', '2014-08-18', 'Active'),
('Shape of You', '{"Shape of You (Acoustic)", "Shape of You - Latin Remix"}', 'T-401.567.890-4', 233, 'Pop', 'English', '2017-01-06', '2017-01-06', 'Active'),
('Uptown Funk', '{"Uptown Funk (feat. Bruno Mars)", "Uptown Funk!"}', 'T-501.678.901-5', 270, 'Funk Pop', 'English', '2014-11-10', '2014-11-10', 'Active'),
('Someone Like You', '{"Someone Like You (Live)", "Someone Like You - Piano Version"}', 'T-601.789.012-6', 285, 'Pop Ballad', 'English', '2011-01-24', '2011-01-24', 'Active'),
('Blinding Lights', '{"Blinding Lights (Remix)", "Blinding Lights - Extended"}', 'T-701.890.123-7', 200, 'Synth Pop', 'English', '2019-11-29', '2019-11-29', 'Active'),
('Crazy in Love', '{"Crazy in Love (feat. Jay-Z)", "Crazy in Love - Solo Version"}', 'T-801.901.234-8', 236, 'R&B', 'English', '2003-05-18', '2003-06-23', 'Active'),
('Bohemian Rhapsody', '{"Bohemian Rhapsody (Remastered)", "Bohemian Rhapsody - Live Aid"}', 'T-902.012.345-9', 355, 'Rock Opera', 'English', '1975-10-31', '1975-10-31', 'Active'),
('Imagine', '{"Imagine (Ultimate Mix)", "Imagine - Raw Studio Mix"}', 'T-903.123.456-0', 183, 'Soft Rock', 'English', '1971-09-09', '1971-09-09', 'Active');

-- Link Writers to Songs (song_writers table)
INSERT INTO song_writers (song_id, writer_id, role, ownership_percentage) VALUES
(1, 1, 'Composer', 50.0), (1, 2, 'Composer', 50.0), -- Hey Jude: Lennon-McCartney
(2, 2, 'Composer', 100.0), -- Yesterday: McCartney
(3, 3, 'Composer', 100.0), -- I Don't Want to Miss a Thing: Diane Warren
(4, 4, 'Composer', 100.0), -- ...Baby One More Time: Max Martin
(5, 5, 'Composer', 50.0), (4, 5, 'Co-writer', 50.0), -- Shake It Off: Taylor Swift & Max Martin
(6, 6, 'Composer', 80.0), (4, 6, 'Producer', 20.0), -- Shape of You: Ed Sheeran & Max Martin
(7, 7, 'Composer', 60.0), (4, 7, 'Producer', 40.0), -- Uptown Funk: Bruno Mars & Max Martin
(8, 8, 'Composer', 100.0), -- Someone Like You: Adele
(9, 9, 'Composer', 70.0), (4, 9, 'Producer', 30.0), -- Blinding Lights: The Weeknd & Max Martin
(10, 10, 'Composer', 100.0), -- Crazy in Love: Beyonce
(11, 1, 'Composer', 25.0), (11, 2, 'Composer', 75.0), -- Bohemian Rhapsody: Primarily McCartney with Lennon
(12, 1, 'Composer', 100.0); -- Imagine: John Lennon

-- Link Publishers to Songs (song_publishers table)
INSERT INTO song_publishers (song_id, publisher_id, ownership_percentage, territory, rights_type) VALUES
(1, 1, 100.0, 'Worldwide', 'Performance'), -- Hey Jude: Sony/ATV
(2, 1, 100.0, 'Worldwide', 'Performance'), -- Yesterday: Sony/ATV
(3, 2, 100.0, 'Worldwide', 'Performance'), -- I Don't Want to Miss a Thing: Universal
(4, 3, 100.0, 'Worldwide', 'Performance'), -- ...Baby One More Time: Warner Chappell
(5, 7, 100.0, 'Worldwide', 'Performance'), -- Shake It Off: Taylor Swift Music
(6, 3, 100.0, 'Worldwide', 'Performance'), -- Shape of You: Warner Chappell
(7, 6, 100.0, 'Worldwide', 'Performance'), -- Uptown Funk: Big Machine Music
(8, 2, 100.0, 'Worldwide', 'Performance'), -- Someone Like You: Universal
(9, 8, 100.0, 'Worldwide', 'Performance'), -- Blinding Lights: XO Music Publishing
(10, 9, 100.0, 'Worldwide', 'Performance'), -- Crazy in Love: Parkwood Entertainment
(11, 1, 100.0, 'Worldwide', 'Performance'), -- Bohemian Rhapsody: Sony/ATV
(12, 1, 100.0, 'Worldwide', 'Performance'); -- Imagine: Sony/ATV

-- Insert Performance Rights data
INSERT INTO performance_rights (song_id, pro_source, performance_date, venue_name, performer, usage_type, revenue_amount, territory) VALUES
(1, 'ASCAP', '2024-01-15', 'WXYZ Radio', 'The Beatles', 'Radio', 45.67, 'US'),
(1, 'BMI', '2024-01-16', 'Spotify', 'Various Artists', 'Streaming', 123.45, 'US'),
(2, 'PRS', '2024-01-17', 'BBC Radio 1', 'Paul McCartney', 'Radio', 67.89, 'UK'),
(3, 'ASCAP', '2024-01-18', 'Netflix', 'Aerosmith', 'Sync', 2500.00, 'US'),
(4, 'BMI', '2024-01-19', 'Apple Music', 'Britney Spears', 'Streaming', 89.12, 'US'),
(5, 'ASCAP', '2024-01-20', 'iHeartRadio', 'Taylor Swift', 'Radio', 156.78, 'US'),
(6, 'PRS', '2024-01-21', 'Spotify UK', 'Ed Sheeran', 'Streaming', 234.56, 'UK'),
(7, 'BMI', '2024-01-22', 'Saturday Night Live', 'Bruno Mars', 'TV', 1200.00, 'US'),
(8, 'PRS', '2024-01-23', 'BBC TV', 'Adele', 'TV', 890.45, 'UK'),
(9, 'SOCAN', '2024-01-24', 'Sirius XM', 'The Weeknd', 'Radio', 78.90, 'CA'),
(10, 'ASCAP', '2024-01-25', 'YouTube Music', 'Beyonce', 'Streaming', 345.67, 'US');

-- Insert Mechanical Rights data
INSERT INTO mechanical_rights (song_id, label_name, artist_name, album_title, release_date, units_sold, rate_per_unit, revenue_amount, territory) VALUES
(1, 'Apple Records', 'The Beatles', 'Hey Jude', '1968-08-26', 5000000, 0.091, 455000.00, 'US'),
(2, 'Parlophone', 'The Beatles', 'Help!', '1965-08-06', 3000000, 0.091, 273000.00, 'UK'),
(3, 'Columbia Records', 'Aerosmith', 'Armageddon Soundtrack', '1998-06-23', 2000000, 0.091, 182000.00, 'US'),
(4, 'Jive Records', 'Britney Spears', '...Baby One More Time', '1999-01-12', 8000000, 0.091, 728000.00, 'US'),
(5, 'Big Machine Records', 'Taylor Swift', '1989', '2014-10-27', 6000000, 0.091, 546000.00, 'US'),
(6, 'Asylum Records', 'Ed Sheeran', '÷ (Divide)', '2017-03-03', 7000000, 0.091, 637000.00, 'UK'),
(7, 'RCA Records', 'Mark Ronson ft. Bruno Mars', 'Uptown Special', '2015-01-13', 4000000, 0.091, 364000.00, 'US'),
(8, 'XL Recordings', 'Adele', '21', '2011-01-24', 9000000, 0.091, 819000.00, 'UK'),
(9, 'XO/Republic Records', 'The Weeknd', 'After Hours', '2020-03-20', 3500000, 0.091, 318500.00, 'US'),
(10, 'Columbia Records', 'Beyonce', 'Dangerously in Love', '2003-06-23', 4500000, 0.091, 409500.00, 'US');
