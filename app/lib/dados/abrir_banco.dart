import 'package:drift_flutter/drift_flutter.dart';

import 'banco_local.dart';

/// Abre o banco local do aparelho. No navegador, usa SQLite em WebAssembly: precisa de
/// `web/sqlite3.wasm` (servido como application/wasm) e `web/drift_worker.js`.
BancoLocal abrirBancoLocal() => BancoLocal(
  driftDatabase(
    name: 'controle_presenca',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ),
);
