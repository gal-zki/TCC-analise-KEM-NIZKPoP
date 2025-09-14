/**
 * @file verificar_prova.c
 * @brief Um programa para verificar uma Prova de Posse de Conhecimento Zero (NIZKPoP)
 * para uma dada chave pública Kyber.
 *
 * Este programa carrega uma chave pública e uma prova de arquivos binários,
 * chama a função de verificação da biblioteca e informa se a prova é válida.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Headers principais da biblioteca Kyber
#include "lib/kyber-zkpop/params.h"
#include "lib/kyber-zkpop/zkpop.h"

/**
 * @brief Função auxiliar para ler um arquivo para um buffer.
 *
 * @param filename O nome do arquivo a ser lido.
 * @param data O ponteiro para o ponteiro que receberá os dados.
 * @return size_t O número de bytes lidos, ou 0 em caso de erro.
 */
size_t read_from_file(const char* filename, uint8_t** data) {
    FILE* fp = fopen(filename, "rb");
    if (!fp) {
        fprintf(stderr, "ERRO: Não foi possível abrir o arquivo %s para leitura.\n", filename);
        return 0;
    }

    fseek(fp, 0, SEEK_END);
    size_t len = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    *data = malloc(len);
    if (!*data) {
        fprintf(stderr, "ERRO: Falha ao alocar memória para o arquivo %s.\n", filename);
        fclose(fp);
        return 0;
    }

    size_t read_len = fread(*data, 1, len, fp);
    if (read_len != len) {
        fprintf(stderr, "ERRO: Falha ao ler todos os bytes de %s.\n", filename);
        fclose(fp);
        free(*data);
        *data = NULL;
        return 0;
    }

    fclose(fp);
    printf("   -> Artefato lido de: %s (%zu bytes)\n", filename, len);
    return len;
}


int main(void) {
    // --- PASSO 1: Alocar memória e carregar artefatos dos arquivos ---
    uint8_t pk[KYBER_PUBLICKEYBYTES];
    uint8_t* zkpop_proof = NULL;
    size_t zkpop_proof_size = 0;

    printf("====================================================\n");
    printf("Verificando Prova de Posse (NIZKPoP)...\n");
    printf("Parâmetros: Kyber%d\n", KYBER_K * 256);
    printf("====================================================\n\n");

    printf("Lendo artefatos dos arquivos...\n");

    // Carregar a chave pública
    FILE* pk_file = fopen("pk.bin", "rb");
    if (!pk_file) {
        fprintf(stderr, "ERRO: Não foi possível abrir pk.bin. Execute ./gerar_prova primeiro.\n");
        return 1;
    }
    if (fread(pk, 1, KYBER_PUBLICKEYBYTES, pk_file) != KYBER_PUBLICKEYBYTES) {
        fprintf(stderr, "ERRO: Falha ao ler a chave pública de pk.bin.\n");
        fclose(pk_file);
        return 1;
    }
    fclose(pk_file);
    printf("   -> Chave pública lida de: pk.bin (%d bytes)\n", KYBER_PUBLICKEYBYTES);

    // Carregar a prova
    zkpop_proof_size = read_from_file("prova.bin", &zkpop_proof);
    if (zkpop_proof_size == 0) {
        fprintf(stderr, "ERRO: Falha ao carregar a prova de prova.bin.\n");
        return 1;
    }

    // --- PASSO 2: Chamar a função de verificação ---
    printf("\nExecutando verificação...\n");
    int result = crypto_nizkpop_verify(pk, zkpop_proof, zkpop_proof_size);

    // --- PASSO 3: Interpretar o resultado ---
    if (result == 0) {
        printf("\n✅ SUCESSO: A prova é VÁLIDA!\n");
    } else {
        printf("\n❌ FALHA: A prova é INVÁLIDA! (Código de erro: %d)\n", result);
    }

    // --- PASSO 4: Liberar a memória alocada para a prova ---
    if (zkpop_proof != NULL) {
        free(zkpop_proof);
        printf("\nMemória da prova foi liberada.\n");
    }

    printf("\nProcesso finalizado.\n");
    return 0;
}
