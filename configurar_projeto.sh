#!/bin/bash

# ==============================================================================
# SCRIPT DE CONFIGURAÇÃO DO PROJETO - KYBER ZKPOP
# ==============================================================================
# Este script copia os arquivos-fonte necessários do repositório original
# do KEM-NIZKPoP para a estrutura de pastas local deste projeto.

# --- VERIFICAÇÃO DE ARGUMENTOS ---
if [ -z "$1" ]; then
    echo "ERRO: Forneça o caminho para o diretório de origem do Kyber (pasta avx2)."
    echo "Uso: ./configurar_projeto.sh /caminho/para/pasta/avx2"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "ERRO: O diretório de origem '$1' não foi encontrado."
    exit 1
fi

# --- DEFINIÇÕES DE CAMINHO ---
DIR_ORIGEM=$1
DIR_DESTINO="lib/kyber-zkpop"
DIR_DESTINO_KECCAK="$DIR_DESTINO/keccak4x"

# --- EXECUÇÃO ---
echo "Configurando o projeto..."

# 1. Cria a estrutura de diretórios de destino
echo "Criando a estrutura de diretórios em '$DIR_DESTINO'..."
mkdir -p "$DIR_DESTINO_KECCAK"

# 2. Copia os arquivos da biblioteca
echo "Copiando arquivos da biblioteca de '$DIR_ORIGEM'..."

# Copia todos os arquivos .c, .h, .S, e .inc da raiz do diretório de origem
# ESTA É A LINHA CORRIGIDA
find "$DIR_ORIGEM" -maxdepth 1 -type f \( -name "*.c" -o -name "*.h" -o -name "*.S" -o -name "*.inc" \) -exec cp {} "$DIR_DESTINO" \;

# 3. Copia os arquivos da subpasta keccak4x
echo "Copiando arquivos de 'keccak4x'..."
find "$DIR_ORIGEM/keccak4x" -maxdepth 1 -type f -exec cp {} "$DIR_DESTINO_KECCAK" \;

echo ""
echo "✅ Configuração concluída com sucesso!"
echo "A biblioteca Kyber com NIZKPoP está pronta para ser compilada."

