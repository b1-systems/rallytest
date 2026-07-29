# Rally-Docker – Quickstart

Dieses Setup baut ein Docker-Image mit [Rally](https://github.com/openstack/rally) 5.0.1
und [rally-openstack](https://github.com/openstack/rally-openstack) 3.0.0, um eine
OpenStack-Cloud mit vordefinierten Benchmark-/Zertifizierungs-Tests
(`build/rally-openstack-tests/`) zu prüfen.

Das Image ist **generisch**: es wird einmal gebaut und kann unverändert
gegen beliebige Zielumgebungen verwendet werden. Alles, was sich pro
Zielumgebung unterscheidet (Zugangsdaten, Testparameter), wird zur
Laufzeit über Volumes ins Image gemountet – ein Rebuild ist dafür nie
nötig.

## Voraussetzungen

- Docker
- Netzwerk-Zugriff vom Docker-Host auf die Keystone-Auth-URL der Zielcloud
  (die Container laufen mit `--network host`)

## 1. Image bauen

Am Dockerfile muss nichts angepasst werden – einmalig bauen:

```bash
cd build
./build.sh
```

Baut das Image als `rallytest:latest`.

## 2. Envfile für die Zielumgebung anlegen

Pro Zielumgebung eine `envfile` mit den echten Zugangsdaten erzeugen,
ausgehend von der Vorlage [`envfile.example`](envfile.example):

```bash
cd ..
cp envfile.example envfile
vim envfile
```

```yaml
openstack:
  auth_url: "https://<keystone-endpoint>:5000/v3"
  region_name: "RegionOne"
  https_insecure: True
  users:
    - username: "admin"
      password: "<password>"
      project_name: "admin"
  admin:
    username: "admin"
    password: "<password>"
    project_name: "admin"
```

`envfile` ist bewusst nicht Teil des Images (kein Rebuild nötig, keine
Zugangsdaten im Image) und sollte nicht eingecheckt werden.

Für mehrere Zielumgebungen einfach mehrere Envfiles pflegen (z. B.
`envfile.kunde-a`, `envfile.kunde-b`) und beim jeweiligen Lauf nach
`envfile` kopieren/verlinken.

## 3. Testparameter anpassen

In [`task_arguments.yaml`](task_arguments.yaml) festlegen, welche Services
getestet werden sollen und mit welchen Eckdaten (Image, Flavor, Nutzer-/
Tenant-Anzahl, Cloud-Größe, Smoke-Mode):

```yaml
---
  service_list:
      - authentication
      # - nova
      #- neutron
      #- keystone
      #- cinder
      #- glance
      #- designate
      #- octavia
  use_existing_users: false
  image_name: "^cirros"
  flavor_name: "2C-1G-10G"
  glance_image_location: "https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img"
  smoke: true
  users_amount: 10
  tenants_amount: 10
  controllers_amount: 3
  compute_amount: 4
  storage_amount: 2
  network_amount: 2
```

`smoke: true` reicht für einen ersten funktionalen Check; für echte
Lasttests auf `smoke: false` setzen und `users_amount`/`tenants_amount`
sowie die `*_amount`-Werte für die Cloud-Größe passend setzen.

## 4. Task starten

```bash
./start.sh
```

Beim Start bootstrapped sich der Container selbst (siehe
[`build/entrypoint.sh`](build/entrypoint.sh)):

- legt die Rally-DB in `db/` an, falls noch keine existiert
- legt das Rally-Environment `openstack-v2` an (aus der gemounteten
  `envfile`), falls es noch nicht existiert
- aktiviert das Environment (`rally env use`)
- führt danach den eigentlichen Rally-Befehl aus
  (`task start task.yaml --task-args-file task_arguments.yaml`)

Das Ganze ist idempotent: DB/Environment werden nur beim allerersten Lauf
gegen eine neue `db/` angelegt, danach übersprungen. Solange `db/`
erhalten bleibt, muss nichts manuell wiederholt werden.

Die Ausgabe zeigt am Ende eine Task-ID, die für den Report gebraucht wird.

Der Environment-Name lässt sich bei Bedarf überschreiben, z. B. um
mehrere Zielumgebungen parallel in derselben `db/` zu verwalten:

```bash
RALLY_ENV_NAME=kunde-a ./start.sh
```

## 5. Report erzeugen

```bash
./get_report.sh <TASK-ID>
```

Erzeugt einen zeitgestempelten HTML-Report unter `reports/` und gibt den
Pfad aus.

## Sonstige Rally-Befehle

Alles, was nicht durch ein eigenes Skript abgedeckt ist, direkt über
`run.sh` an Rally durchreichen, z. B.:

```bash
./run.sh task list
./run.sh task status <TASK-ID>
./run.sh env list
./run.sh env check openstack-v2
```

## Troubleshooting

- **Bootstrap schlägt fehl / `env check` meldet Fehler**: Zugangsdaten/
  Auth-URL in der `envfile` (Schritt 2) prüfen. Danach reicht ein erneuter
  Lauf von `run.sh`/`start.sh` – das Environment wird beim nächsten Start
  automatisch neu versucht anzulegen, wenn es beim letzten Mal nicht
  entstanden ist.
- **ERROR rally oslo_db.exception.DBNonExistentDatabase: unable to open database file**:
  das `db/` Verzeichnis muss die OID/GID 1000 mit 0755 besitzen.
- **Kein Netzwerkzugriff auf die Cloud**: Container laufen mit
  `--network host` – prüfen, ob der Docker-Host selbst die Auth-URL
  erreichen kann.
- **DB/Environment weg**: Ordner `db/` darf zwischen Läufen nicht gelöscht
  werden, sonst wird beim nächsten Start alles (DB + Environment) neu
  angelegt.
- **Andere Zielumgebung ausprobieren**: einfach eine andere `envfile`
  nach `envfile` kopieren und ggf. `RALLY_ENV_NAME` setzen (siehe oben) –
  kein Rebuild, kein manueller Container-Zugriff nötig.
