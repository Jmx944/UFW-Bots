#!/bin/bash
# UFW Bots
# Ecrit par jmx94.fr
# Copyright jmx94.fr
# Apache License 2.0
# Github: https://github.com/Jmx944

if ! dpkg -s ufw &>/dev/null; then
    echo "UFW n'est pas installé. Installation en cours..."
    sudo apt update
    sudo apt install -y ufw
    echo "UFW a été installé avec succès."
fi

default_script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

bloquer_ips() {
    urls=(
        "https://github.com/ShadowWhisperer/IPs/raw/master/Other/Scanners"
        # Ajoutez d'autres URLs au besoin
    )

    for url in "${urls[@]}"
    do
        curl -sSL "$url" | while read -r ip; do
            if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                if ! sudo ufw status | grep -q " $ip "; then
                    sudo ufw deny from "$ip"
                    echo "Adresse IP $ip bloquée."
                else
                    echo "Adresse IP $ip est déjà bloquée. Ignorée."
                fi
            else
                echo "Adresse IP $ip invalide. Ignorée."
            fi
        done
    done

    sudo ufw reload
    echo "Toutes les adresses IP des listes ont été bloquées."
}

activer_ufw() {
    sudo ufw --force enable
    echo "UFW activé."
}

desactiver_ufw() {
    sudo ufw disable
    echo "UFW désactivé."
}

autoriser_port_ssh() {
    read -p "Veuillez saisir le numéro de port SSH (par défaut 22): " port_ssh
    port_ssh=${port_ssh:-22}  # Utilise le port 22 par défaut si aucun port n'est spécifié
    sudo ufw allow "$port_ssh"/tcp
    echo "Port SSH autorisé sur le port $port_ssh."
}

definir_allow() {
    sudo ufw default allow
    echo "Le comportement par défaut de UFW est désormais 'ALLOW'."
}

definir_drop() {
    sudo ufw default deny
    echo "Le comportement par défaut de UFW est désormais 'DROP'."
}

ajouter_cron() {
    read -p "Veuillez saisir le chemin du script (par défaut: $default_script_path) : " script_path
    script_path=${script_path:-$default_script_path}
    cron_job="0 3 * * * $script_path -block-ips-silence"

       if crontab -l | grep -qF "$cron_job"; then
        read -p "La tâche cron existe déjà. Voulez-vous la supprimer ? (O/N) : " choix
        case $choix in
            [Oo]*)
                (crontab -l | grep -vF "$cron_job" && echo "") | crontab - ;;
            [Nn]*) ;;
            *) echo "Choix invalide. La tâche cron n'a pas été modifiée." ;;
        esac
    else
        export EDITOR=nano
        (crontab -l ; echo "$cron_job") | crontab -
        echo "La tâche cron a été ajoutée avec succès pour exécuter le script toutes les 24 heures."
    fi
}

if [[ $1 == "-block-ips-silence" ]]; then
    bloquer_ips &>/dev/null
    exit
fi

# Menu principal
while true; do
    echo "Menu :"
    echo "1. Bloquer les adresses IP (Scanners)"
    echo "2. Activer UFW"
    echo "3. Désactiver UFW"
    echo "4. Autoriser le port SSH"
    echo "5. Définir le comportement par défaut de UFW sur 'ALLOW'"
    echo "6. Définir le comportement par défaut de UFW sur 'DROP'"
    echo "7. Ajouter la tâche cron pour bloquer les IP toutes les 24h"
    echo "8. Quitter"

    read -p "Entrez votre choix : " choix

    case $choix in
        1) bloquer_ips;;
        2) activer_ufw;;
        3) desactiver_ufw;;
        4) autoriser_port_ssh;;
        5) definir_allow;;
        6) definir_drop;;
        7) ajouter_cron;;
        8) exit;;
        *) echo "Choix invalide";;
    esac
done
