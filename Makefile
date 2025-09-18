CC ?= /usr_bin/cc
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

# --- DEFINIÇÃO DAS FONTES ---

# Lista de fontes base da biblioteca
SOURCES = lib/kyber-zkpop/kem.c lib/kyber-zkpop/indcpa.c lib/kyber-zkpop/polyvec.c \
  lib/kyber-zkpop/poly.c lib/kyber-zkpop/fq.S lib/kyber-zkpop/shuffle.S \
  lib/kyber-zkpop/ntt.S lib/kyber-zkpop/invntt.S lib/kyber-zkpop/basemul.S \
  lib/kyber-zkpop/consts.c lib/kyber-zkpop/rejsample.c lib/kyber-zkpop/cbd.c \
  lib/kyber-zkpop/verify.c

SOURCESKECCAK   = $(SOURCES) lib/kyber-zkpop/fips202.c lib/kyber-zkpop/fips202x4.c \
  lib/kyber-zkpop/symmetric-shake.c lib/kyber-zkpop/keccak4x/KeccakP-1600-times4-SIMD256.c

# Fontes para os programas de benchmark (incluindo cpucycles.c e speed_print.c)
BENCH_SOURCES_BASE = $(SOURCESKECCAK) lib/kyber-zkpop/randombytes.c lib/kyber-zkpop/cpucycles.c lib/kyber-zkpop/speed_print.c
BENCH_PROVA_SOURCES = $(BENCH_SOURCES_BASE) lib/kyber-zkpop/zkpop.c

# Fontes para os programas de aplicação (sem cpucycles.c e speed_print.c)
APP_SOURCES_BASE = $(SOURCESKECCAK) lib/kyber-zkpop/randombytes.c
APP_PROVA_SOURCES = $(APP_SOURCES_BASE) lib/kyber-zkpop/zkpop.c

# --- ALVOS PRINCIPAIS ---

.PHONY: all clean benchmarks apps

# make command will build everything
all: benchmarks apps

# Only benchmarks
benchmarks: benchmark_padrao benchmark_nizkpop benchmark_verificacao

# Builds files for examples
apps: gerar_prova verificar_prova gerar_chave_padrao

# --- BENCHMARK COMPILATION RULES ---

benchmark_padrao: $(BENCH_SOURCES_BASE) benchmark_padrao.c
	$(CC) $(CFLAGS) $(BENCH_SOURCES_BASE) benchmark_padrao.c -o benchmark_padrao

benchmark_nizkpop: $(BENCH_PROVA_SOURCES) benchmark_nizkpop.c
	$(CC) $(CFLAGS) $(BENCH_PROVA_SOURCES) benchmark_nizkpop.c -o benchmark_nizkpop

benchmark_verificacao: $(BENCH_PROVA_SOURCES) benchmark_verificacao.c
	$(CC) $(CFLAGS) $(BENCH_PROVA_SOURCES) benchmark_verificacao.c -o benchmark_verificacao


# --- EXAMPLES COMPILATION RULES ---

gerar_prova: $(APP_PROVA_SOURCES) gerar_prova.c
	$(CC) $(CFLAGS) $(APP_PROVA_SOURCES) gerar_prova.c -o gerar_prova

verificar_prova: $(APP_PROVA_SOURCES) verificar_prova.c
	$(CC) $(CFLAGS) $(APP_PROVA_SOURCES) verificar_prova.c -o verificar_prova
	
gerar_chave_padrao: $(APP_SOURCES_BASE) gerar_chave_padrao.c
	$(CC) $(CFLAGS) $(APP_SOURCES_BASE) gerar_chave_padrao.c -o gerar_chave_padrao

# --- CLEAN GARBAGE FILES ---
clean:
	-$(RM) -f benchmark_padrao benchmark_nizkpop benchmark_verificacao
	-$(RM) -f gerar_prova verificar_prova gerar_chave_padrao
	-$(RM) -f lib/kyber-zkpop/*.o lib/kyber-zkpop/keccak4x/*.o

