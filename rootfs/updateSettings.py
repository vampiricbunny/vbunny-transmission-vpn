#!/usr/bin/env python3
import json
import os

def update_settings():
    transmission_home = os.environ.get('TRANSMISSION_HOME', '/config/transmission-home')
    settings_file = os.path.join(transmission_home, 'settings.json')
    default_settings_path = '/defaults/transmission-default-settings.json'

    with open(default_settings_path, 'r') as f:
        settings = json.load(f)

    if os.path.exists(settings_file):
        try:
            with open(settings_file, 'r') as f:
                user_settings = json.load(f)
                settings.update(user_settings)
        except Exception:
            pass

    settings["rpc-bind-address"] = "0.0.0.0"
    settings["bind-address-ipv4"] = "0.0.0.0"
    settings["bind-address-ipv6"] = "::"

    settings["rpc-whitelist-enabled"] = False
    settings["rpc-whitelist"] = "*"
    settings["rpc-host-whitelist-enabled"] = False
    settings["rpc-host-whitelist"] = "*"

    env_map = {
        'TRANSMISSION_DOWNLOAD_DIR': 'download-dir',
        'TRANSMISSION_INCOMPLETE_DIR': 'incomplete-dir',
        'TRANSMISSION_WATCH_DIR': 'watch-dir',
        'TRANSMISSION_RPC_PORT': 'rpc-port',
        'TRANSMISSION_RPC_USERNAME': 'rpc-username',
        'TRANSMISSION_RPC_PASSWORD': 'rpc-password'
    }

    for env_var, key in env_map.items():
        value = os.environ.get(env_var)
        if value:
            if key == 'rpc-port':
                try:
                    settings[key] = int(value)
                except ValueError:
                    settings[key] = 9091
            else:
                settings[key] = value

    rpc_user = os.environ.get('TRANSMISSION_RPC_USERNAME', '')
    rpc_pass = os.environ.get('TRANSMISSION_RPC_PASSWORD', '')

    if rpc_user and rpc_pass:
        settings['rpc-authentication-required'] = True
        settings['rpc-username'] = rpc_user
        settings['rpc-password'] = rpc_pass
    else:
        settings['rpc-authentication-required'] = False
        settings['rpc-username'] = ''
        settings['rpc-password'] = ''

    os.makedirs(transmission_home, exist_ok=True)
    with open(settings_file, 'w') as f:
        json.dump(settings, f, indent=4)

if __name__ == '__main__':
    update_settings()
