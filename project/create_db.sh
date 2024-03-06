#!/bin/bash

DB_FILE="./db/messages.db"

rm -rf "$DB_FILE"

sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS messages (
    timestamp TEXT,
    system TEXT,
    message TEXT,
    target_type TEXT,
    target_id TEXT,
    target_x TEXT,
    target_y TEXT
);
EOF

if [ $? -eq 0 ]; then
    echo "Database created successfully."
else
    echo "Error creating database."
fi
