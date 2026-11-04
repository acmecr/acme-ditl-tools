
<div align="center">

# acme-ditl-tools 

Set de scripts para coleta de DNS passivo com Entrada 2

<br>

Os scripts foram desenvolvidos para serem executados dentro do servidor DNS onde a coleta será feita. O tráfego observado é capturado em arquivos PCAPs, e então enviados a uma instância do Entrada2.  


---

A metodologia de coleta e seus os scripts foram adaptados dos utilizados no programa ["A Day in the Life of the Internet"](https://www.caida.org/projects/ditl/), realizado pelo DNS-OARC.

</div>

<br>
<br>


# Instruções de deploy

As etapas a seguir descrevem o processo de instalação, configuração e início da coleta.

<br>

## Etapas iniciais

Entre no usuário root

```bash
su root
```

Troque seu diretório para `/opt/` (diretorio presumido no exemplo de configuracao) e clone o repositorio:

```bash
cd /opt/
git clone https://github.com/acmecr/acme-ditl-tools
```

Crie o diretório de coleta

```bash
mkdir -p /var/lib/acme-ditl/captures/ 
```
*localização alterável nas configurações*

Neste diretório tembém são armazenados pcaps que não foram enviados em instâncias onde o endpoint MinIO do Entrada 2 não esteja disponível.

<br>


## Dependências

Os scripts dependem primariamente dos seguintes pacotes:

- dnscap
- chrony 

Realize a instalação com os seguintes comandos:

```bash
sudo apt update
sudo apt install dnscap chrony
```

<br>


## Configure os parametros da coleta

Cria o arquivo de configuração local a partir do template:

```bash
cp -v scripts/settings.example.sh scripts/settings.sh
```

Configure os parâmetros da coleta baseados nas instruções:

```bash
vim scripts/settings.sh
```

## Configure o endpoint da coleta via mc (MinIO Client)

O MinIO Client (mc) é uma ferramenta de gerência de objetos S3. Ele é utilizado para o upload dos pcaps coletados ao Entrada 2.

Seus binários estão inclusos neste repositório por conveniência.

Certifique de que as credenciais do mc foram declaradas no seu `settings.sh`, e execute o comando para a configuração automática do endpoint:

```bash
./scripts/setup-minio-alias.sh
```

## Valide as configurações, teste a coleta

Execute o teste de validação dos scripts:

```bash
make check
```

Inicie a coleta manualmente em foreground:

```bash
./scripts/capture-dnscap.sh
```
*certifique-se de que você ainda esteja logado como root*

O script irá realizar testes iniciais e imprimir o comando do dnscap resultante das configurações.

Verifique se a coleta está ocorrendo após o intervalo definido em `settings.sh` 

No diretório local:
```bash
ls -lh /var/lib/acme-ditl/captures/
```
No Entrada2:
```bash
minio-binaries/mc ls minio/sidnlabs-iceberg-data/pcap-done/
minio-binaries/mc ls minio/sidnlabs-iceberg-data/pcap-in/
```

Após verificar que a coleta está sendo realizada como desejado, encerre a coleta em foreground e prossiga:

*(encerre o processo de coleta na janela em que ele foi iniciado)*
```
CTRL+C
```

## Instale o serviço do systemd para habilitar a coleta após cada boot

O serviço incluso nesse repositório realiza o agendamento automático da coleta.

Copie o arquivo para o diretório de serviços do systemd e habilite a coleta durante o boot:

```bash
cp systemd/coleta-entrada2.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now coleta-entrada2.service
```

Verifique o funcionamento do serviço

```bash
systemctl status coleta-entrada2.service
```

```bash
journalctl -u coleta-entrada2.service
```

Verifique novamente se a coleta está gerando dados após o intervalo definido:

No diretório local:

```bash
ls -lh /var/lib/acme-ditl/captures/
```

No Entrada2:

```bash
minio-binaries/mc ls minio/sidnlabs-iceberg-data/pcap-done/
minio-binaries/mc ls minio/sidnlabs-iceberg-data/pcap-in/
```


---

<div align="center">

Pronto! Desfrute de sua coleta de dados!

</div>
