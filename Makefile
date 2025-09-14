CC ?= /usr/bin/cc
# Adicionamos a flag -Ilib/kyber-zkpop para incluir o diretório da biblioteca
CFLAGS += -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
  -Wshadow -Wpointer-arith -mavx2 -mbmi2 -mpopcnt -maes \
  -march=native -mtune=native -O3 -fomit-frame-pointer -Ilib/kyber-zkpop
NISTFLAGS += -Wno-unused-result -mavx2 -mbmi2 -mpopcnt -maes \
  -march=native -mtune=native -O3 -fomit-frame-pointer -Ilib/kyber-zkpop
PROFILEFLAGS += -Wno-unused-result -mavx2 -mbmi2 -mpopcnt -maes \
  -march=native -mtune=native -O3 -g -pg -DPROFILE -Ilib/kyber-zkpop
RM = /bin/rm

ifneq "$(ZKPOP_N)" ""
CFLAGS+= -DZKPOP_N=$(ZKPOP_N)
PROFILEFLAGS+= -DZKPOP_N=$(ZKPOP_N)
endif
ifneq "$(ZKPOP_TAU)" ""
CFLAGS+= -DZKPOP_TAU=$(ZKPOP_TAU)
PROFILEFLAGS+= -DZKPOP_TAU=$(ZKPOP_TAU)
endif
ifneq "$(NO_RESAMPLING)" ""
CFLAGS+= -DNO_RESAMPLING
PROFILEFLAGS+= -DNO_RESAMPLING
endif

# Lista de fontes com o caminho correto para a biblioteca
SOURCES = lib/kyber-zkpop/kem.c lib/kyber-zkpop/indcpa.c lib/kyber-zkpop/polyvec.c \
  lib/kyber-zkpop/poly.c lib/kyber-zkpop/fq.S lib/kyber-zkpop/shuffle.S \
  lib/kyber-zkpop/ntt.S lib/kyber-zkpop/invntt.S lib/kyber-zkpop/basemul.S \
  lib/kyber-zkpop/consts.c lib/kyber-zkpop/rejsample.c lib/kyber-zkpop/cbd.c \
  lib/kyber-zkpop/verify.c

SOURCESKECCAK   = $(SOURCES) lib/kyber-zkpop/fips202.c lib/kyber-zkpop/fips202x4.c \
  lib/kyber-zkpop/symmetric-shake.c lib/kyber-zkpop/keccak4x/KeccakP-1600-times4-SIMD256.c

# Lista de fontes para os nossos novos executáveis.
PROVA_SOURCES_BASE = $(SOURCESKECCAK) lib/kyber-zkpop/randombytes.c lib/kyber-zkpop/zkpop.c
PADRAO_SOURCES_BASE = $(SOURCESKECCAK) lib/kyber-zkpop/randombytes.c

.PHONY: all clean gerar_prova verificar_prova gerar_chave_padrao

all: gerar_prova verificar_prova gerar_chave_padrao

# Alvo para criar o executável 'gerar_prova'
gerar_prova: $(PROVA_SOURCES_BASE) gerar_prova.c
	$(CC) $(CFLAGS) $(PROVA_SOURCES_BASE) gerar_prova.c -o gerar_prova

# Alvo para criar o executável 'verificar_prova'
verificar_prova: $(PROVA_SOURCES_BASE) verificar_prova.c
	$(CC) $(CFLAGS) $(PROVA_SOURCES_BASE) verificar_prova.c -o verificar_prova

# NOVO ALVO: para criar o executável 'gerar_chave_padrao'
gerar_chave_padrao: $(PADRAO_SOURCES_BASE) gerar_chave_padrao.c
	$(CC) $(CFLAGS) $(PADRAO_SOURCES_BASE) gerar_chave_padrao.c -o gerar_chave_padrao

# --- ALVO CLEAN ---
clean:
	-$(RM) -f gerar_prova verificar_prova gerar_chave_padrao
	-$(RM) -f lib/kyber-zkpop/*.o lib/kyber-zkpop/keccak4x/*.o

