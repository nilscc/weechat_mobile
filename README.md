# weechat

Weechat Relay Client for iOS and Android

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# API Relay

## nginx Reverse Proxy

To route Weechat API websockets through nginx, set the following proxy settings:

https://nginx.org/en/docs/http/websocket.html

Then enable the non-SSL version of the API protocol:

    /relay add api 9000

Make sure to block external access, e.g. in your firewall settings:

    $ sudo ufw deny 9000