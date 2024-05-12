-- Represent users of the service
    CREATE TABLE Users(
    id SERIAL,
    username VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(255) UNIQUE NOT NULL,
    PRIMARY KEY (id)
);

-- Represent items and their owners
CREATE TABLE User_items(
    owner_id INT,
    item_id SERIAL,
    item_name VARCHAR(255) NOT NULL,
    description TEXT,
    PRIMARY KEY (item_id),
    FOREIGN KEY (owner_id) REFERENCES Users(id) ON UPDATE CASCADE
);

-- Create custom type for exchange status column
CREATE TYPE status_type AS ENUM('ACCEPTED', 'PENDING', 'DECLINED');

-- Represent exchange requests history
CREATE TABLE exchange_requests(
    id SERIAL,
    user_from INT,
    user_to INT,
    user_from_item_id INT,
    user_to_item_id INT,
    date TIMESTAMP DEFAULT NOW(),
    status status_type DEFAULT 'PENDING',
    PRIMARY KEY (id),
    FOREIGN KEY (user_from) REFERENCES Users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (user_to) REFERENCES Users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (user_from_item_id) REFERENCES User_items(item_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (user_to_item_id) REFERENCES User_items(item_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Represent list of the users for regular user of the service, protecting privacy-sensitive information
CREATE VIEW users_list AS
    SELECT id, username, LEFT(phone_number, 3) || REPEAT('*', LENGTH(phone_number) - 2) AS phone_number
    FROM users;

-- Represent all items owned by current user
CREATE VIEW My_items AS
    SELECT ui.item_name, ui.description
    FROM User_items ui
    JOIN Users u ON ui.owner_id = u.id
    WHERE u.username = CURRENT_USER;

-- Represent all items available for exchange for current user
CREATE VIEW Items_to_exchange AS
    SELECT u.username AS owner_name, ui.item_name, ui.description
    FROM Users u
    JOIN User_items ui on ui.owner_id = u.id
    WHERE u.username != CURRENT_USER;

-- Represent all incoming exchange requests for current user
CREATE VIEW incoming_requests AS
SELECT
        u_from.username AS user_from,
        ui_from.item_name AS user_item,
        ui_from.description AS user_item_description,
        ui_to.item_name AS my_item,
        er.date,
        er.status
FROM Exchange_requests er
JOIN Users u_from ON er.user_from = u_from.id
JOIN Users u_to ON er.user_to = u_to.id
JOIN User_items ui_from ON er.user_from_item_id = ui_from.item_id
JOIN User_items ui_to ON er.user_to_item_id = ui_to.item_id
WHERE er.status = 'PENDING'
AND u_to.username = CURRENT_USER;

-- Allow regular user to update request status without accessing privacy-protected table directly
CREATE RULE update_accepted_status AS
    ON UPDATE TO incoming_requests
    DO INSTEAD (
        UPDATE exchange_requests
        SET status = NEW.status
        WHERE date = OLD.date;
    );


-- Check item ownership and update owners or decline request
CREATE FUNCTION validate_and_exchange()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM User_items
        WHERE owner_id = OLD.user_from AND item_id = OLD.user_from_item_id
    )
    OR NOT EXISTS (
        SELECT 1 FROM User_items
        WHERE owner_id = OLD.user_to AND item_id = OLD.user_to_item_id
    )
    THEN
	UPDATE exchange_requests
        SET status = 'DECLINED'
        WHERE exchange_requests.date = OLD.date;
	RAISE NOTICE 'One of the users does not own required item anymore. Exchange declined.';
	RETURN NEW;
    ELSE
        UPDATE User_items
        SET owner_id = NEW.user_to
        WHERE item_id = NEW.user_from_item_id;

        UPDATE User_items
        SET owner_id = NEW.user_from
        WHERE item_id = NEW.user_to_item_id;
        RETURN NEW;
    END IF;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Begin exchange validation process
CREATE TRIGGER exchange_request_check
AFTER UPDATE OF status ON exchange_requests
FOR EACH ROW
WHEN (NEW.status = 'ACCEPTED')
EXECUTE FUNCTION validate_and_exchange();

-- Create exchange request from current user
CREATE FUNCTION exchange(user_to VARCHAR(255), user_item VARCHAR(255), my_item VARCHAR(255))
RETURNS VOID
AS $$
BEGIN
    INSERT INTO Exchange_requests (user_from, user_to, user_from_item_id, user_to_item_id)
    SELECT u_from.id, u_to.id, ui_from.item_id, ui_to.item_id
    FROM users_list u_to
    JOIN users_list u_from ON u_from.username = CURRENT_USER
    JOIN user_items ui_to ON ui_to.owner_id = u_to.id
    JOIN user_items ui_from ON ui_from.owner_id = u_from.id
    WHERE u_to.username = user_to
      AND ui_to.item_name = user_item
      AND ui_from.item_name = my_item;
END;
$$ LANGUAGE plpgsql;

-- Create indexes to speed common operations
CREATE INDEX idx_user_username ON users (username);
CREATE INDEX idx_user_items_item_name ON user_items (item_name);







