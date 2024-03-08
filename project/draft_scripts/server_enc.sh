#!/bin/bash

password="password123"
salt="mysalt"

# encoded="$(echo "$encrypted_message" | cut -d '.' -f 1)"
# hash="$(echo "$encrypted_message" | cut -d '.' -f 2)"
# decrypted=$(echo "$encoded" | base64 -d | openssl enc -aes-256-cbc -d -k $password)
# calculated_hash=$(echo -n "$decrypted$salt" | sha256sum | cut -d ' ' -f 1)

# if [ "$hash" == "$calculated_hash" ]; then
#     echo "Хэш-сумма верна."
#     echo "Расшифрованное сообщение: $decrypted"
# else
#     echo "Хэш-сумма не совпадает. Возможно, данные повреждены."
# fi

while true; do
    while read encrypted_message; do
        echo "encrypted_message[$encrypted_message]"
        echo 1
        decrypted=$(echo -n "$encrypted_message" | base64 -d | openssl enc -aes-256-cbc -d -k $password)
        echo "$decrypted"
        # decrypted="$(echo "$encrypted_message" | cut -d '.' -f 1 | openssl enc -aes-256-cbc -d -k $password)"
        # hash="$(echo "$encrypted_message" | cut -d '.' -f 2)"
        # -d decrypt, -k key
        echo 3
        # calculated_hash=$(echo -n "$decrypted$salt" | sha256sum | cut -d ' ' -f 1)
        echo 5
        # echo "$calculated_hash ===== $hash"
    done < <(nc -l 8081)
done
