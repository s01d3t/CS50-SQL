-- Create users
CREATE USER smolkat WITH PASSWORD '1';
CREATE USER happyuni WITH PASSWORD '1';
CREATE USER president WITH PASSWORD '1';

-- Create group 
CREATE GROUP users;

-- Grant privileges to the group
GRANT USAGE ON SCHEMA public TO users;
GRANT SELECT ON my_items TO users;
GRANT SELECT ON items_to_exchange TO users;
GRANT SELECT, UPDATE ON incoming_requests TO users;
GRANT UPDATE, INSERT on exchange_requests TO users;
GRANT USAGE ON SEQUENCE exchange_requests_id_seq TO users;
GRANT SELECT ON users_list TO users;
GRANT SELECT ON user_items TO users;

-- Grant group membership to users
GRANT users TO smolkat, happyuni, president;

-- Filling up database with users information
INSERT INTO Users(username, phone_number)
VALUES
    ('smolkat', '+44 1234567890'),
    ('happyuni', '+44 1234567891'),
    ('president', '+7 9876543210'),
    ('friendlyuser12', '+44 1234567892'),
    ('f0rg1v3m3', '+7 9876543211'),
    ('idk', '+1 8765432109');

-- Define existing items and assign ownership randomly
INSERT INTO user_items (owner_id, item_name, description)
VALUES
    (1, 'Book', 'Fascinating book with an engaging plot'),
    (2, 'Laptop', 'Powerful laptop for work and entertainment'),
    (3, 'USB Flash Drive', '32 GB flash drive'),
    (4, 'Headphones', 'Wireless headphones with good sound quality'),
    (5, 'Camera', 'Professional DSLR camera for photography enthusiasts'),
    (6, 'Smartphone', 'Latest smartphone model with advanced features'),
    (1, 'Tablet', 'Lightweight tablet with a high-resolution display'),
    (2, 'Backpack', 'Spacious backpack with multiple compartments'),
    (3, 'Guitar', 'Acoustic guitar for music lovers'),
    (4, 'Sunglasses', 'Stylish sunglasses for sunny days'),
    (5, 'Fitness Tracker', 'Track your fitness goals with this advanced fitness tracker'),
    (6, 'Water Bottle', 'Reusable water bottle for staying hydrated on the go'),
    (1, 'Running Shoes', 'Comfortable running shoes for your daily jog'),
    (2, 'Yoga Mat', 'High-quality yoga mat for your yoga practice'),
    (3, 'Dumbbells', 'Set of dumbbells for your home workouts'),
    (4, 'Resistance Bands', 'Versatile resistance bands for strength training'),
    (5, 'Gaming Console', 'Latest gaming console for immersive gaming experience'),
    (6, 'Virtual Reality Headset', 'Explore virtual worlds with this VR headset'),
    (1, 'Wireless Controller', 'Ergonomic wireless controller for gaming comfort'),
    (2, 'Gaming Chair', 'Comfortable gaming chair with adjustable features'),
    (3, 'Coffee Maker', 'Coffee maker for brewing delicious coffee at home'),
    (4, 'Travel Mug', 'Insulated travel mug to keep your beverages hot or cold'),
    (5, 'Tea Infuser', 'Stainless steel tea infuser for brewing loose leaf tea'),
    (6, 'Electric Kettle', 'Fast-boiling electric kettle for your tea or coffee needs');

-- Log in as user with "happyuni" username
SET ROLE happyuni;

-- Find all users of the service
SELECT * FROM users_list;

-- Find all items owned by current user
SELECT * FROM my_items;

-- Find all items available for exchange for current user
SELECT * FROM items_to_exchange;

-- Create exchange request with prepared function
SELECT exchange('smolkat', 'Book', 'Laptop');

-- Log in as user with "president" username 
SET ROLE president;

-- Create exchange request with prepared function
SELECT exchange('smolkat', 'Book', 'Guitar');

-- Log in as user with "smolkat" username
SET ROLE smolkat;

-- Find all incoming exchange requests
SELECT * FROM incoming_requests;

-- Accept exchange request
UPDATE incoming_requests
SET status = 'ACCEPTED'
WHERE user_item = 'Guitar';

-- Decline exchange request
UPDATE incoming_requests
SET status = 'DECLINED'
WHERE user_item = 'Laptop';










