#!/bin/bash

USR_EX=$1

function user_exists_by_id() {
    id "$1" &>/dev/null
}

if user_exists_by_id $USR_EX; then
    # Matar processos do usuário
    pkill -u $USR_EX

    # Deletar o usuário
    userdel $USR_EX
fi

exit 0
