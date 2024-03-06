#!/bin/bash

# 1. поиск исполняемых файлов в каталогах /bin, /usr/bin, если файлы являются скриптами, то скопировать в папку ~/bin и добавить расширение в зависимости от используемого интерпретатора ( name.bash; name.sh; name.perl и т.д.);
# 2. вывести на экран количество файлов каждого интерпретатора;
# 3. запросить у пользователя какие расширения оставить, остальные удалить;
# 4. запуск скрипта разрешить только пользователю student.

# 3* спрашиваем, какие удалить

# source="./bin ./usr/bin"

source="/bin /usr/bin" # где происходит поиск скриптов
dest="./target" # куда копируем

interpreters=()
while IFS= read -r filename; do
    # content=$(<$filename)
    content=$(cat $filename 2> /dev/null) 
    # извлечение шебанга из содержимого файла 
    shebang_line=$(echo "$content" | head -n 1 | grep -oE '^#!/[^ ]+')
    # удаление всех символов до последнего "/"
    interpreter=${shebang_line##*/}
    
    if [[ -n $interpreter ]]; then
        new_filename="`basename $filename`.$interpreter"
        cp $filename $dest/$new_filename
        interpreters+=("$interpreter")
    fi
# `file filename` должен содержать "script"
done < <(find $source -type f -exec file {} + | grep -G ":.*script" | cut -d: -f 1)

# вывод количества найденных скриптов по интерпретаторам 
echo $(printf "%s\n" "${interpreters[@]}" | sort | uniq -c)

# добавление уникальных интерпретаторов в массив uniq_interpreters
uniq_interpreters=()
while IFS= read -r tmp; do
    uniq_interpreters+=($tmp)
done < <(printf "%s\n" "${interpreters[@]}" | sort | uniq)

function del_scripts() {
  rm $dest/*.$1
}

PS3="Which scripts to remove? "
while true; do
  select del_interpreter in "${uniq_interpreters[@]}"; do
    del_scripts $del_interpreter
  done
done

## from root
# useradd apple
# sudo chown apple main.sh
# sudo chmod u+x,ga-x main.sh
