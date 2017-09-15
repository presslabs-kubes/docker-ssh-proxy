#!/bin/bash
set -eo pipefail

if [ -z "$AUTHORIZED_KEYS" ] ; then
    echo "You must define AUTHORIZED_KEYS environment varaible" >&2
    exit 1
fi

if [ -z "$FORWARD_ADDRESS" ] ; then
    echo "You must define FORWARD_ADDRESS environment varaible" >&2
    exit 1
fi

echo "$AUTHORIZED_KEYS" | while read -r key ; do
    echo "no-pty,no-X11-forwarding,permitopen=\"$FORWARD_ADDRESS\",command=\"/bin/echo do-not-send-commands\" $key" >> /home/sshproxy/.ssh/authorized_keys
done

: ${SSHD_HOST_KEYS_DIR:="/run/sshd_host_keys"}

if [ ! -d "$SSHD_HOST_KEYS_DIR" ] ; then
    mkdir -p "$SSHD_HOST_KEYS_DIR"
fi

if [ -z "$(ls -A "$SSHD_HOST_KEYS_DIR")" ] ; then
    for key_type in dsa rsa ecdsa ed25519 ; do
        ssh-keygen -t "$key_type" -P "" -f "$SSHD_HOST_KEYS_DIR/ssh_host_${key_type}_key"
    done
fi

cp $SSHD_HOST_KEYS_DIR/*_key /etc/ssh
cp $SSHD_HOST_KEYS_DIR/*_key.pub /etc/ssh
chmod 0600 /etc/ssh/*_key

exec "$@"
