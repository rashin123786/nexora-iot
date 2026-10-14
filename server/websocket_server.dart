import 'dart:io';

final clients = <WebSocket>{};

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);

  print('WebSocket server running on port 8080');

  await for (final request in server) {
    print('REQUEST: ${request.method} ${request.uri}');
    print('UPGRADE: ${request.headers.value('upgrade')}');
    if (request.uri.path != '/ws') {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found');
      await request.response.close();
      continue;
    }

    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('WebSocket upgrade required');
      await request.response.close();
      continue;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    clients.add(socket);

    print('Client connected: ${clients.length}');

    socket.listen(
      (message) {
        if (message is! String) return;

        print('Received: $message');

        for (final client in clients.toList()) {
          if (client.readyState == WebSocket.open) {
            client.add(message);
          }
        }
      },
      onDone: () {
        clients.remove(socket);
        print('Client disconnected');
      },
      onError: (error) {
        clients.remove(socket);
        print('WebSocket error: $error');
      },
      cancelOnError: true,
    );
  }
}
