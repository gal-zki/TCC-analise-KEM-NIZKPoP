CC ?= /usr/bin/cc
# Adicionamos a flag -Ilib/kyber-zkpop para incluir o diretório da biblioteca
CFLAGS += -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
  -Wshadow -Wpointer-arith -mavx2 -mbmi2 -mpopcnt -maes \
  -march=native -mtune=native -O3 -fomit-frame-pointer -Ilib/kyber-zkpop
RM = /bin/rm

ifneq "$(ZKPOP_N)" ""
CFLAGS+= -DZKPOP_N=$(ZKPOP_N)
endif
ifneq "$(ZKPOP_TAU)" ""
CFLAGS+= -DZKPOP_TAU=$(ZKPOP_TAU)
endif

# Lista de fontes com o caminho correto para a biblioteca
SOURCES = lib/kyber-zkpop/kem.c lib/kyber-zkpop/indcpa.c lib/kyber-zkpop/polyvec.c \
  lib/kyber-zkpop/poly.c lib/kyber-zkpop/fq.S lib/kyber-zkpop/shuffle.S \
  lib/kyber-zkpop/ntt.S lib/kyber-zkpop/invntt.S lib/kyber-zkpop/basemul.S \
  lib/kyber-zkpop/consts.c lib/kyber-zkpop/rejsample.c lib/kyber-zkpop/cbd.c \
  lib/kyber-zkpop/verify.c

SOURCESKECCAK   = $(SOURCES) lib/kyber-zkpop/fips202.c lib/kyber-zkpop/fips202x4.c \
  lib/kyber-zkpop/symmetric-shake.c lib/kyber-zkpop/keccak4x/KeccakP-1600-times4-SIMD256.c

# Adicionamos cpucycles.c às fontes base
BENCH_SOURCES_BASE = $(SOURCESKECCAK) lib/kyber-zkpop/randombytes.c lib/kyber-zkpop/cpucycles.c
PROVA_SOURCES = $(BENCH_SOURCES_BASE) lib/kyber-zkpop/zkpop.c

.PHONY: all clean benchmarks

all: benchmarks

benchmarks: benchmark_padrao benchmark_nizkpop benchmark_verificacao

# Alvo para o benchmark de geração padrão
benchmark_padrao: $(BENCH_SOURCES_BASE) benchmark_padrao.c
	$(CC) $(CFLAGS) $(BENCH_SOURCES_BASE) benchmark_padrao.c -o benchmark_padrao

# Alvo para o benchmark de geração NIZKPoP
benchmark_nizkpop: $(PROVA_SOURCES) benchmark_nizkpop.c
	$(CC) $(CFLAGS) $(PROVA_SOURCES) benchmark_nizkpop.c -o benchmark_nizkpop

# Alvo para o benchmark de verificação NIZKPoP
benchmark_verificacao: $(PROVA_SOURCES) benchmark_verificacao.c
	$(CC) $(CFLAGS) $(PROVA_SOURCES) benchmark_verificacao.c -o benchmark_verificacao

clean:
	-$(RM) -f benchmark_padrao benchmark_nizkpop benchmark_verificacao
	-$(RM) -f lib/kyber-zkpop/*.o lib/kyber-zkpop/keccak4x/*.o

