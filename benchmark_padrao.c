/**
 * @file benchmark_padrao.c
 * @brief Mede os ciclos de CPU para a geração de chaves Kyber padrão.
 * Usa o framework de medição do repositório original.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "lib/kyber-zkpop/kem.h"
#include "lib/kyber-zkpop/cpucycles.h"
#include "lib/kyber-zkpop/speed_print.h"

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "Uso: %s <numero_de_testes>\n", argv[0]);
        return 1;
    }

    int ntests = atoi(argv[1]);
    uint8_t pk[KYBER_PUBLICKEYBYTES];
    uint8_t sk[KYBER_SECRETKEYBYTES];
    uint64_t *t = malloc(ntests * sizeof(uint64_t));
    if (!t) return -1;
    
    for (int i = 0; i < ntests; i++) {
        t[i] = cpucycles();
        crypto_kem_keypair(pk, sk);
    }
    
    print_results("cycles_padrao", t, ntests);
    
    free(t);
    return 0;
}

