// Binding usado só nos testes: as migrações lidas de db/migrations.
declare namespace Cloudflare {
  interface Env {
    TEST_MIGRATIONS: import('cloudflare:test').D1Migration[];
  }
}
