#!/bin/bash
pipe=/tmp/myfifo
mkfifo $pipe

while true; do
  if read line <$pipe; then
    if [[ "$line" == 'quit' ]]; then
      break
    fi
    echo "Сервер получил: $line"
  fi
done

rm -f $pipe


# #!/bin/bash
# pipe=/tmp/myfifo

# echo "Сообщение 1" >$pipe
# sleep 1
# echo "Сообщение 2" >$pipe
# sleep 1
# echo "quit" >$pipe
# sleep 1


# проблема - во время чтения нового сообщения, остальные потом не читаются сервером....
