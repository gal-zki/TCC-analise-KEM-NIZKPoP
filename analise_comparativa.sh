#!/bin/bash

# ==============================================================================
# SCRIPT DE ANÁLISE COMPARATIVA PARA O TCC - KYBER ZKPOP
# ==============================================================================
# Este script compara a geração de chaves com NIZKPoP versus a geração padrão,
# medindo o overhead de tempo e espaço, e realizando uma análise de entropia
# comparativa para detectar vieses.

# --- CONFIGURAÇÕES ---

# Número de vezes que cada geração será executada para obter uma média de tempo
NUM_EXECUCOES=10

# Número de amostras a serem geradas para a análise de concatenação de entropia
NUM_AMOSTRAS_ENTROPIA=100

# Arquivos de saída
ARQUIVO_CSV="resultados_comparativos.csv"
ARQUIVO_ENTROPIA="resultados_entropia_comparativa.log"

# Lista de pares (N, Tau) para testar.
declare -a PARAMS=(
    "4 64" "8 43" "16 32" "31 26" "57 22"
    "107 19" "256 16" "371 15" "921 13"
)

# --- INÍCIO DO SCRIPT ---

echo "Iniciando análise comparativa..."
echo "Resultados de performance serão salvos em: $ARQUIVO_CSV"
echo "Resultados de entropia serão salvos em: $ARQUIVO_ENTROPIA"

# Prepara os arquivos de resultado
echo "N,Tau,Tempo_Padrao_ms,Tempo_NIZKPoP_ms,Overhead_Tempo_%,Tamanho_Prova_Bytes" > "$ARQUIVO_CSV"
rm -f "$ARQUIVO_ENTROPIA" # Limpa o log de entropia antigo

# --- PARTE 1: ANÁLISE DE PERFORMANCE ---

echo ""
echo "--- Iniciando Análise de Performance (Tempo e Espaço) ---"

# Compila o gerador padrão uma única vez, pois ele não depende de N e Tau
echo "Compilando o gerador de chave padrão..."
make clean > /dev/null
make gerar_chave_pmakadrao

# Mede o tempo do gerador padrão
echo "Medindo performance da geração padrão..."
total_time_padrao=0
for (( i=1; i<=$NUM_EXECUCOES; i++ )); do
    # Usa `time -p` e extrai o tempo "real"
    exec_time=$( (time -p ./gerar_chave_padrao) 2>&1 | awk '/real/ {print $2}' )
    total_time_padrao=$(echo "$total_time_padrao + $exec_time" | bc)
done
avg_time_padrao=$(echo "scale=2; ($total_time_padrao / $NUM_EXECUCOES) * 1000" | bc | cut -d. -f1)

# Itera sobre os parâmetros (N, Tau) para o NIZKPoP
for param_pair in "${PARAMS[@]}"; do
    read -r N Tau <<< "$param_pair"
    echo "------------------------------------------------------------"
    echo "Processando parâmetros NIZKPoP: N = $N, Tau = $Tau"
    echo "------------------------------------------------------------"

    # Compila o gerador NIZKPoP com os parâmetros atuais
    make clean > /dev/null
    make ZKPOP_N=$N ZKPOP_TAU=$Tau gerar_prova

    # Mede o tempo do gerador NIZKPoP
    total_time_nizkpop=0
    for (( i=1; i<=$NUM_EXECUCOES; i++ )); do
        exec_time=$( (time -p ./gerar_prova) 2>&1 | awk '/real/ {print $2}' )
        total_time_nizkpop=$(echo "$total_time_nizkpop + $exec_time" | bc)
    done
    avg_time_nizkpop=$(echo "scale=2; ($total_time_nizkpop / $NUM_EXECUCOES) * 1000" | bc | cut -d. -f1)
    
    # Pega o tamanho da prova (executa uma vez só para isso)
    ./gerar_prova > /dev/null
    tamanho_prova=$(stat -c%s "prova.bin")

    # Calcula o overhead de tempo em porcentagem
    overhead=$(echo "scale=2; (($avg_time_nizkpop - $avg_time_padrao) / $avg_time_padrao) * 100" | bc)

    # Salva os resultados no CSV
    echo "$N,$Tau,$avg_time_padrao,$avg_time_nizkpop,$overhead,$tamanho_prova" >> "$ARQUIVO_CSV"
    echo "Resultados para (N=$N, Tau=$Tau) salvos."
done

echo ""
echo "--- Análise de Performance concluída. ---"


# --- PARTE 2: ANÁLISE DE ENTROPIA ---
echo ""
echo "--- Iniciando Análise de Entropia (Viés na Geração) ---"

TMP_DIR=$(mktemp -d)
echo "Diretório temporário para amostras: $TMP_DIR"

# Gera amostras para a análise de entropia
echo "Gerando $NUM_AMOSTRAS_ENTROPIA amostras para análise de viés..."
# Compila o gerador NIZKPoP com os parâmetros padrão para a geração em massa
make clean > /dev/null
make ZKPOP_N=4 ZKPOP_TAU=64 gerar_prova > /dev/null
make gerar_chave_padrao > /dev/null

for i in $(seq 1 $NUM_AMOSTRAS_ENTROPIA); do
    ./gerar_chave_padrao > /dev/null
    mv sk_padrao.bin "$TMP_DIR/sk_padrao_$i.bin"

    ./gerar_prova > /dev/null
    mv sk.bin "$TMP_DIR/sk_nizkpop_$i.bin"
    mv prova.bin "$TMP_DIR/prova_$i.bin"
    echo -n "."
done
echo ""

# Concatena as amostras
echo "Concatenando amostras para análise..."
cat "$TMP_DIR"/sk_padrao_*.bin > sks_padrao_concatenadas.bin
cat "$TMP_DIR"/sk_nizkpop_*.bin > sks_nizkpop_concatenadas.bin
cat "$TMP_DIR"/prova_*.bin > provas_concatenadas.bin

# Limpa o diretório temporário
rm -rf "$TMP_DIR"

# Analisa a entropia dos arquivos concatenados e salva no log
{
    echo "####################################################################"
    echo "Análise Comparativa de Entropia ($NUM_AMOSTRAS_ENTROPIA amostras)"
    echo "####################################################################"
    echo ""
    echo "--- Chaves Secretas Padrão (sks_padrao_concatenadas.bin) ---"
    ent sks_padrao_concatenadas.bin
    echo ""
    echo "--- Chaves Secretas com NIZKPoP (sks_nizkpop_concatenadas.bin) ---"
    ent sks_nizkpop_concatenadas.bin
    echo ""
    echo "--- Provas NIZKPoP (provas_concatenadas.bin) ---"
    ent provas_concatenadas.bin
    echo ""
} >> "$ARQUIVO_ENTROPIA"

echo "Análise de entropia salva em $ARQUIVO_ENTROPIA"
echo ""
echo "✅ Análise comparativa completa!"
