#!/bin/bash

# ==============================================================================
# SCRIPT DE ANÁLISE PARA O TCC - KYBER ZKPOP (VERSÃO 2)
# ==============================================================================
# Este script automatiza a geração e análise de artefatos criptográficos
# para diferentes parâmetros (N, Tau) e realiza uma análise de viés por
# concatenação de múltiplas amostras.

# --- CONFIGURAÇÕES ---

# Número de vezes que cada geração será executada para obter uma média de tempo
NUM_EXECUCOES=10

# Número de amostras a serem geradas para a análise de concatenação
NUM_AMOSTRAS_CONCAT=100

# Arquivo de saída para os dados de performance e tamanho (formato CSV)
ARQUIVO_CSV="resultados_performance.csv"

# Arquivo de saída para os dados de entropia
ARQUIVO_ENTROPIA="resultados_entropia.log"

# Lista de pares (N, Tau) para testar. Adicione ou remova conforme necessário.
declare -a PARAMS=(
    "4 64"
    "8 43"
    "16 32"
    "31 26"
    "57 22"
    "107 19"
    "256 16"
    "371 15"
    "921 13"
)

# --- INÍCIO DO SCRIPT ---

echo "Iniciando análise de performance e entropia..."
echo "Os resultados de performance serão salvos em: $ARQUIVO_CSV"
echo "Os resultados de entropia serão salvos em: $ARQUIVO_ENTROPIA"

# Limpa arquivos de resultados antigos
> "$ARQUIVO_CSV"
> "$ARQUIVO_ENTROPIA"

# Escreve o cabeçalho do arquivo CSV
echo "N,Tau,Tempo_Medio_ms,Tamanho_Prova_Bytes" >> "$ARQUIVO_CSV"

# Loop principal sobre cada par de parâmetros
for param in "${PARAMS[@]}"; do
    # Separa N e Tau
    read -r N TAU <<< "$param"

    echo "------------------------------------------------------------"
    echo "Processando parâmetros: N = $N, Tau = $TAU"
    echo "------------------------------------------------------------"

    # 1. Compilar o código com os parâmetros atuais
    echo "Compilando com N=$N e Tau=$TAU..."
    make clean > /dev/null
    make ZKPOP_N=$N ZKPOP_TAU=$TAU gerar_prova > /dev/null

    if [ ! -f ./gerar_prova ]; then
        echo "ERRO: Falha na compilação para N=$N, Tau=$TAU. Abortando."
        exit 1
    fi

    # 2. Executar a geração várias vezes e medir o tempo
    echo "Executando $NUM_EXECUCOES vezes para medir o tempo..."
    total_time=0
    for (( i=1; i<=$NUM_EXECUCOES; i++ )); do
        exec_time_sec=$( { time -p ./gerar_prova > /dev/null; } 2>&1 | grep real | awk '{print $2}' )
        total_time=$(echo "$total_time + ($exec_time_sec * 1000)" | bc)
    done

    avg_time_ms=$(echo "scale=2; $total_time / $NUM_EXECUCOES" | bc)

    # 3. Obter o tamanho da prova
    tamanho_prova=$(stat -c%s prova.bin)

    # 4. Salvar os resultados de performance no CSV
    echo "$N,$TAU,$avg_time_ms,$tamanho_prova" >> "$ARQUIVO_CSV"
    echo "Resultados salvos: N=$N, Tau=$TAU, Tempo Médio=${avg_time_ms}ms, Tamanho=${tamanho_prova}B"

    # 5. Analisar a entropia dos artefatos (da última execução)
    echo "Analisando entropia dos artefatos..."
    {
        echo "======================================================="
        echo "Análise de Entropia para N=$N, Tau=$TAU (Amostra Única)"
        echo "======================================================="
        echo "--- Chave Pública (pk.bin) ---"
        ent pk.bin
        echo ""
        echo "--- Chave Secreta (sk.bin) ---"
        ent sk.bin
        echo ""
        echo "--- Prova ZKPoP (prova.bin) ---"
        ent prova.bin
        echo ""
    } >> "$ARQUIVO_ENTROPIA"
    echo "Análise de entropia salva em $ARQUIVO_ENTROPIA"

done

# --- ANÁLISE DE VIÉS (CONCATENAÇÃO) ---
echo "------------------------------------------------------------"
echo "Iniciando análise de viés por concatenação..."
echo "Usando os últimos parâmetros compilados (N=$N, Tau=$TAU)"
echo "Gerando $NUM_AMOSTRAS_CONCAT amostras..."
echo "------------------------------------------------------------"

# Cria um diretório temporário para as amostras
TMP_DIR="amostras_temp"
mkdir -p "$TMP_DIR"

# Gera múltiplas amostras
for i in $(seq 1 $NUM_AMOSTRAS_CONCAT); do
    ./gerar_prova > /dev/null
    mv pk.bin "$TMP_DIR/pk_$i.bin"
    mv sk.bin "$TMP_DIR/sk_$i.bin"
    mv prova.bin "$TMP_DIR/prova_$i.bin"
    # Adiciona um ponto para feedback visual
    echo -n "."
done
echo "" # Nova linha

# Concatena as amostras em arquivos grandes
echo "Concatenando amostras..."
cat "$TMP_DIR"/pk_*.bin > pks_concatenadas.bin
cat "$TMP_DIR"/sk_*.bin > sks_concatenadas.bin
cat "$TMP_DIR"/prova_*.bin > provas_concatenadas.bin

# Analisa a entropia dos arquivos concatenados
echo "Analisando entropia dos arquivos concatenados..."
{
    echo ""
    echo "#######################################################"
    echo "Análise de Entropia de Artefatos Concatenados ($NUM_AMOSTRAS_CONCAT amostras)"
    echo "#######################################################"
    echo ""
    echo "--- Chaves Públicas Concatenadas (pks_concatenadas.bin) ---"
    ent pks_concatenadas.bin
    echo ""
    echo "--- Chaves Secretas Concatenadas (sks_concatenadas.bin) ---"
    ent sks_concatenadas.bin
    echo ""
    echo "--- Provas ZKPoP Concatenadas (provas_concatenadas.bin) ---"
    ent provas_concatenadas.bin
    echo ""
} >> "$ARQUIVO_ENTROPIA"

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf "$TMP_DIR"
rm pks_concatenadas.bin sks_concatenadas.bin provas_concatenadas.bin

echo "------------------------------------------------------------"
echo "Análise concluída com sucesso!"
echo "------------------------------------------------------------"
