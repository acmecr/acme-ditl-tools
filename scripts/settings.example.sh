#!/bin/sh

#
# ************** CONFIGURACAO BASICA  *******************
#

# defina o nome do ponto de coleta
#
NODENAME=""
#NODENAME="[local]-[funcao]-[instancia]"

# exemplos: 
#   NODENAME="unesp-reitoria-dns1"
#   NODENAME="unesp-recursivo-dns2"
#   NODENAME="assis-autoritativo-dns1"
#

#
# ************** DEFINICAO DE ESCOPO DA COLETA *******************
#
# os parametros abaixo podem ser utilizados para filtrar a coleta
# adequando-a diferentes casos de uso
# 
#   IFACES - interfaces onde o trafego sera capturado
#   DESTINATIONS - filtrar a coleta apenas as transacoes dos
#                         servidores atuando como responders 
#   QUERIES_ONLY - coletar apenas consultas
# 
# (veja os exemplos de caso de uso abaixo)
#
IFACES="eth0"
DESTINATIONS="" 
QUERIES_ONLY="no"

#
# ------ exemplo: captura de trafego de clientes em servidor recursivo ------
#
#IFACES="eth0"
#DESTINATIONS="10.0.0.53" # apenas transacoes onde esse IP e o responder
#QUERIES_ONLY="no"
# 
# captura consultas ao recursivo e suas respostas aos clientes,
# exclui as consultas recursivas originadas pelo proprio servidor
# 
# clientes <-> recursivo
#             (10.0.0.53)
#
# --------------------------------------------------------------------------

#
# ------ exemplo: captura de trafego total em servidor recursivo ------
#
#IFACES="eth0 eth1"
#DESTINATIONS=""
#QUERIES_ONLY="no"
# 
# captura todo trafego DNS visivel nas interfaces
#
# clientes <-> recursivo <-> upstream
#
# ---------------------------------------------------------------------

#
# ------ exemplo: coleta otimizada para servidor autoritativo ------
#
#IFACES="eth0"
#DESTINATIONS="192.0.2.53 2001:db8::53"
#QUERIES_ONLY="no"
#
# captura consultas ao autoritativos e suas respostas aos clientes
# filtra a coleta apenas aos enderecos de IP desejados 
# (util em caso da interface ser usada por multiplos servicos) 
#
# clientes <-> autoritativo
#         (192.0.2.53 / 2001:db8::53)
# 
# ---------------------------------------------------------------------


#
# ************** FILTROS SECUNDARIOS  *******************
#

DO_TCP="yes"	# capturar DNS-over-TCP
#DO_TCP="no"	# ignorar DNS-over-TCP

DO_FRAGS="yes"	# capturar fragmented DNS
#DO_FRAGS="no"	# ignorar fragmented DNS
# obs: (a captura de fragmented DNS pode inserir pacotes nao-DNS nos dados)
#

#
# ************** CONFIGURACOES EM RUNTIME *******************
#

# intervalo de tempo para cada pcap
#
#    (um intervalo menor pode melhorar performance 
#     em ambientes com volume de trafego pesado)
#
INTERVAL="600"   	# (10min por pcap)
#INTERVAL="300" 	# ( 5min por pcap) 


#
# ************** ARMAZENAMENTO / UPLOAD *******************
#


# ---
# diretorio de destino aos pcaps gerados pelo dnscap
SAVEDIR=""

# ---
# path ao script que deve ser executado apos o processamento de cada pcap  
KICK_CMD="/opt/acme-ditl-tools/scripts/pcap-submit-to-oarc.sh"

#  (path do script que executa apos o cada pcap e finalizado pelo dnscap)  
#

# ---
# deletar os arquivos apos seu upload ao entrada
RM_AFTER_UPLOAD=""

#  yes -> "deleta os arquivos de captura apos confirmar upload no minio" 
#  no -> "os arquivos da coleta permanecem no disco local" 
# 

# parametros de sincronizacao do chrony: 
#
CHRONY_MAX_CORRECTION="0.5"
CHRONY_CHECK_INTERVAL="2"
CHRONY_TRIES="6"

#
#  - exigir correcao do clock para menos que 0.5s de erro  
#  - aguardar 2 segundos para cada tentativa
#  - maximo de 6 tentativas (cancela o inicido coleta) 
#
# obs:
#  (o proceso de sincronizaco acontece apenas 
#   na inicializacao da coleta) 
#

#
# ************** ENTRADA / MINIO *******************
#

# credenciais 
# 
MC_ENDPOINT=""
MC_SECRET_KEY=""

# exemplo:
#   MC_ENDPOINT="http://<SEU-IP-ENTRADA2>:9000"
#   MC_SECRET_KEY="minha-senha-de-teste-nao-producao"
#

# path do executavel do minio-client
MC="/root/minio-binaries/mc"

# alias padrao do endpoint  
MC_ALIAS="minio"
MC_ACCESS_KEY="admin"

# ponto ingestao de pcaps 
REMOTE="${MC_ALIAS}/sidnlabs-iceberg-data/pcap-in/"

#
# ************ parametros opcionais ***************
#

# --- path do executavel dnscap ----
#
DNSCAP="/usr/bin/dnscap"

#   altere este path caso o dnscap esteja instalado,
#   mas nao e encontrado pelos scripts,
#
#   para encontrar o path:
#     (como root) 
#     $ whereis dnscap 
#


# --- coleta em uma janela de tempo pre definida ---
# 
#START_T=""
#STOP_T=""

# exemplo:
#  "quero coletar dados no dia 10/08/2040!"
#
#   START_T="2040-08-10 00:00:00"
#   STOP_T="2040-08-11 00:00:00"
#

# ---

