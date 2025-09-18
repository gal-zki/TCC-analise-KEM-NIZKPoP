/**
 * @file gerar_chave_padrao.c
 * @brief Programa para gerar um par de chaves Kyber padrão (sem NIZKPoP).
 *
 * Este programa chama a função crypto_kem_keypair da biblioteca original
 * para servir como linha de base para análises de performance comparativa.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "lib/kyber-zkpop/kem.h"
#include "lib/kyber-zkpop/params.h"

// Função auxiliar para salvar arquivos (reutilizada de gerar_prova.c)
int save_to_file(const char* filename, const uint8_t* data, size_t len) {
    FILE* fp = fopen(filename, "wb");
    if (!fp) {
        fprintf(stderr, "ERRO: Não foi possível abrir o arquivo %s para escrita.\n", filename);
        return -1;
    }
    if (fwrite(data, 1, len, fp) != len) {
        fprintf(stderr, "ERRO: Falha ao escrever todos os bytes em %s.\n", filename);
        fclose(fp);
        return -1;
    }
    fclose(fp);
    return 0;
}

int main() {
    uint8_t pk[KYBER_PUBLICKEYBYTES];
    uint8_t sk[KYBER_SECRETKEYBYTES];

    printf("Gerando par de chaves Kyber padrão (sem NIZKPoP)...\n");

    if (crypto_kem_keypair(pk, sk) != 0) {
        fprintf(stderr, "ERRO: Falha ao gerar o par de chaves padrão.\n");
        return 1;
    }

    printf("Salvando chaves em pk_padrao.bin e sk_padrao.bin...\n");
    save_to_file("pk_padrao.bin", pk, KYBER_PUBLICKEYBYTES);
    save_to_file("sk_padrao.bin", sk, KYBER_SECRETKEYBYTES);

    printf("Chaves padrão geradas com sucesso.\n");

    return 0;
}
