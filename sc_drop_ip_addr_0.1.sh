### Скрипт для блокировки IP-адреса, которые генерируют от 20 http|https запросов на один uri в минуту и не принадлежат РФ.
#!/bin/bash

#создать файл для логов
touch /var/log/temp_d.txt
touch /var/log/temp_t.txt
chmod 777 /var/log/temp_d.txt #Присвоить права
chmod 777 /var/log/temp_t.txt

#Переменные директорий
path_to_log_f1="/var/log/temp_d.txt"
path_to_log_f2="/var/log/temp_t.txt"

#Максимальное количество запросов
num_of_req_allowed=30

#Количество секунд за которое собирать инфу
max_time=10

#Функция для удобства использования
drop_warn_ip ()
{
#Собрать все в лог
tcpdump -i any -s 0 -n  'tcp port https' or 'tcp port http' > /var/log/temp_d.txt

#Собирать $max_time секунд
#sleep $max_time
#Функция запрещающая ip адресу доступ
drop_ip_addr ()
{
       iptables -t filter -A INPUT -s "$ip_addr_get"/32 -j DROP
       service iptables save
       systemctl restart iptables

}

#Сортировать по количеству
grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /var/log/temp_d.txt | sort | uniq -c | sort -nr > /var/log/temp_t.txt

#Удалить лишние пробелы в начале
sed -e 's/^[ \t]*//' -e 's/[ \t]*$//' /var/log/temp_t.txt > /var/log/temp_d.txt

#Получаем количество строк в файле
number_of_lines="$(cat /var/log/temp_d.txt | wc -l)"


#Теперь дербаним файл на переменные, счетчик количество строк
while [[ $number_of_lines -ne 1 ]]; do
        get_num_inq="$(cat $path_to_log_f1 | cut -d' ' -f1 | tr -cd '[[:digit:]]')"
         if [[ $num_of_req_allowed -le $get_num_inq ]]
         then
                ip_addr_get="$(cat $path_to_log_f1 | cut -d' ' -f2)"
                drop_ip_addr
         fi
        let "number_of_lines=$number_of_lines-1"
 done
drop_warn_ip
}
drop_warn_ip
