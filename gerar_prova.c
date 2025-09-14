/**
 * @file gerar_prova.c
 * @brief Um programa para gerar um par de chaves Kyber (pk, sk) e uma
 * prova de posse de conhecimento zero (NIZKPoP) da chave secreta.
 *
 * Este programa chama a função principal da biblioteca modificada do Kyber,
 * imprime o tamanho dos artefatos gerados e os salva em arquivos binários
 * para uso posterior.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Headers principais da biblioteca Kyber
#include "lib/kyber-zkpop/api.h"
#include "lib/kyber-zkpop/params.h"
#include "lib/kyber-zkpop/zkpop.h"

/**
 * @brief Função auxiliar para salvar um buffer de bytes em um arquivo.
 *
 * @param filename O nome do arquivo a ser criado.
 * @param data O ponteiro para os dados a serem salvos.
 * @param len O número de bytes a serem escritos.
 * @return int 0 em caso de sucesso, -1 em caso de erro.
 */
int save_to_file(const char* filename, const uint8_t* data, size_t len) {
    FILE* fp = fopen(filename, "wb");
    if (!fp) {
        fprintf(stderr, "ERRO: Não foi possível abrir o arquivo %s para escrita.\n", filename);
        return -1;
    }
    size_t written = fwrite(data, 1, len, fp);
    if (written != len) {
        fprintf(stderr, "ERRO: Falha ao escrever todos os bytes em %s.\n", filename);
        fclose(fp);
        return -1;
    }
    fclose(fp);
    printf("   -> Artefato salvo em: %s (%zu bytes)\n", filename, len);
    return 0;
}


int main(void) {
    // --- PASSO 1: Alocar memória para as saídas ---
    // Buffer para a chave pública
    uint8_t pk[KYBER_PUBLICKEYBYTES];
    // Buffer para a chave secreta
    uint8_t sk[KYBER_SECRETKEYBYTES];

    // A prova (zkpop) será alocada dinamicamente pela função.
    // Inicializamos o ponteiro como NULL.
    uint8_t* zkpop_proof = NULL;
    size_t zkpop_proof_size = 0;

    printf("====================================================\n");
    printf("Gerando par de chaves Kyber e Prova de Posse (NIZKPoP)...\n");
    printf("Parâmetros: Kyber%d\n", KYBER_K * 256);
    printf("====================================================\n\n");

    // --- PASSO 2: Chamar a função principal para gerar os artefatos ---
    int result = crypto_kem_keypair_nizkpop(pk, sk, &zkpop_proof, &zkpop_proof_size);

    // --- PASSO 3: Verificar o resultado e usar os artefatos ---
    if (result == 0 && zkpop_proof != NULL) {
        printf("✅ Geração concluída com sucesso!\n\n");
        printf("Tamanhos dos artefatos gerados:\n");
        printf("   - Chave Pública (pk): %d bytes\n", KYBER_PUBLICKEYBYTES);
        printf("   - Chave Secreta (sk): %d bytes\n", KYBER_SECRETKEYBYTES);
        printf("   - Prova (NIZKPoP):    %zu bytes\n\n", zkpop_proof_size);

        printf("Salvando artefatos em arquivos...\n");
        save_to_file("pk.bin", pk, KYBER_PUBLICKEYBYTES);
        save_to_file("sk.bin", sk, KYBER_SECRETKEYBYTES);
        save_to_file("prova.bin", zkpop_proof, zkpop_proof_size);
        printf("\nArquivos salvos com sucesso.\n");

    } else {
        fprintf(stderr, "❌ ERRO durante a geração da prova. Código de erro: %d\n", result);
        // Se a prova foi alocada mesmo com erro, tente liberar
        if (zkpop_proof != NULL) {
            free(zkpop_proof);
        }
        return 1; // Retorna um código de erro
    }

    // --- PASSO 4: Liberar a memória que foi alocada para a prova ---
    // Este passo é crucial para evitar vazamentos de memória.
    if (zkpop_proof != NULL) {
        free(zkpop_proof);
        printf("\nMemória da prova foi liberada.\n");
    }

    printf("\nProcesso finalizado.\n");
    return 0;
}
