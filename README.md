# acme-ditl-tools 

Este repositório contém uma série de scripts que realizam a coleta de consultas em um servidor DNS, e envia os pacotes capturados a uma instância do ENTRADA2, que converte os pacotes para o formato Apache Parquet, consideravelmente otimizando o armazenamento de dados.

Os scripts para a realização da coleta foram adaptados dos utilizados no programa ["A Day in the Life of the Internet"](https://www.caida.org/projects/ditl/), realizado pelo DNS-OARC.

# Instruções para deploy

As etapas a seguir descrevem o processo para iniciar a coleta de dados e os enviarem ao ENTRADA2. 

## Etapas iniciais

- Verifique se a data e o horário do servidor no qual as ferramentas de coleta serão instaladas estão corretos e sincronizados com o seu respectivo servidor NTP
- Mude o usuário para root e entre em seu diretório padrão em /root/. Isto é necessário pois os scripts devem ser executados como superusuário. Desta forma, é vantajoso realizar a configuração no diretório de root.

### Instale DNSCAP

A ferramenta dnscap é utilizada pelos scripts para realizar a captura de pacotes do sistema. É recomendado utilizar [a versão 1.7.1 da ferramenta, disponível no site do DNS-OARC](https://dnscap.dns-oarc.net/). 

Realize a instalação com os seguintes comandos:

```
$ sudo apt install gcc net-tools
$ sudo apt-get install libpcap-dev
$ curl -O https://dnscap.dns-oarc.net/dnscap-1.7.1.tar.gz
$ tar -xvzf dnscap-1.7.1
$ cd dnscap-1.7.1/
$ ./configure
$ make install 
```

### Instale o mc (MinIO Client)

O MinIO é uma ferramenta de armazenamento em cloud. O ENTRADA2 utiliza um servidor MinIO para receber os dados de coleta de um servidor DNS. 

Realize a instalação do MinIO Client na máquina seguindo as [instruções oficiais](https://docs.min.io/enterprise/aistor-object-store/reference/cli/).

Em seguida, configure um endpoint que aponta ao servidor hospedando o ENTRADA2:

```
# minio/binaries/mc alias set minio http://{IP-DO-ENTRADA2-AQUI}:9000 admin {SUA-SENHA} 
```

OBS: Execute o comando acima como root! As configurações de alias são salvas para cada usuário.

### Configuração dos scripts

Os scripts de coleta utilizam dnscap para realizar a captura de consultas DNS no servidor e os enviam para o servidor do MinIO presente na instância do ENTRADA2.

Lembre de realizar todo o processo como root! no diretorio /root!

Transfira [o diretório de ferramentas de coleta](https://github.com/acmecr/acme-ditl-tools/) para a máquina.

Crie um diretório `captures/` na sua `$HOME`.

Edite o arquivo em `scripts/.env`, com as informações do seu servidor:

```
CAPTURE_DIR=/root/captures
MINIO_BIN_DIR=/root/minio-binaries
MINIO_ALIAS_IP=
MINIO_ALIAS_PASSWORD=
IFACES=
SERVER_NAME=
KICK_CMD=/root/acme-ditl-tools/scripts/pcap-submit-to-oarc.sh
TIME_INTERVAL=600
```

### Executando o projeto e criando crontab

Para testar a coleta, execute o comando:

```
$ sudo sh capture-dnscap.sh
```

e entre na interface web do MinIO Object Store do ENTRADA2 (acesse via `http://{seu_IP_servidor_Entrada2}:9090`), e veja se os dados aparecem na pasta `sidnlabs-iceberg-data/pcap-done`.

Caso o teste for bem sucedido, adicione a seguinte linha no seu arquivo crontab para que a coleta se inicie em cada boot:

```
@reboot cd /root/ditl-tools/scripts/ && sh capture-dnscap.sh
```
