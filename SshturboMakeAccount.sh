#!/bin/bash
username=$1
password=$2
dias=$3
sshlimiter=$4

# Verificar se o usuário existe
if ! id "$username" &>/dev/null; then
    grep -v ^$username[[:space:]] /root/usuarios.db >/tmp/ph
    cat /tmp/ph >/root/usuarios.db
    final=$(date "+%Y-%m-%d" -d "+$dias days")
    gui=$(date "+%d/%m/%Y" -d "+$dias days")
    pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
    useradd -e $final -M -s /bin/false -p $pass $username 2>/dev/null
    echo "$password" >/etc/SSHPlus/senha/$username
    echo "$username $sshlimiter" >>/root/usuarios.db
fi
