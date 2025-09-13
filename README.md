# Análise de Prova de Posse de Conhecimento Zero para o Kyber KEM
Este repositório contém o código-fonte e as ferramentas de análise desenvolvidas para o Trabalho de Conclusão de Curso (TCC) intitulado "Avaliação do Uso de Provas de Zero Conhecimento na Autenticação de Posse de Chaves em Mecanismos de Encapsulamento de Chaves (KEM)".
O projeto investiga a implementação de Provas de Posse de Conhecimento Zero Não-Interativas (NIZKPoP) para o esquema criptográfico pós-quântico CRYSTALS-Kyber, com foco na análise de performance e na geração de artefatos.
## Base Científica e Créditos
Este trabalho é uma extensão prática e uma análise do esquema proposto no artigo "Proof-of-Possession for KEM Certificates using Verifiable Generation". Todo o crédito pelo esquema criptográfico e pela implementação base pertence aos autores originais.
* **Artigo Científico:** Güneysu, T., et al. (2022). Proof-of-Possession for KEM Certificates using Verifiable Generation. ACM SIGSAC Conference on Computer and Communications Security.
  * Link: https://doi.org/10.1145/3548606.3560560
* **Repositório Original:** A implementação base foi adaptada do repositório oficial dos autores.
  * Link: https://github.com/Chair-for-Security-Engineering/KEM-NIZKPoP
## Estrutura do Repositório
O código-fonte original do Kyber com NIZKPoP foi isolado no diretório ```lib/kyber-zkpop/``` para funcionar como uma biblioteca. As contribuições deste projeto (ferramentas de análise e scripts) estão localizadas no diretório raiz para facilitar o acesso e destacar o trabalho desenvolvido.
## Contribuições Deste Repositório
* ```gerar_prova.c```: Ferramenta de linha de comando para gerar um par de chaves Kyber (pk, sk) e sua correspondente NIZKPoP. Os artefatos são salvos como ```pk.bin```, ```sk.bin```, e ```prova.bin```.
* ```verificar_prova.c```: Ferramenta para carregar uma chave pública e uma prova a partir de arquivos e verificar sua validade.
* ```analise.sh```: Script de análise automatizado que compila o projeto com diferentes parâmetros ```(N, Tau)```, executa benchmarks de performance e realiza análises estatísticas (entropia) sobre os artefatos gerados.
## Como Compilar e Executar
### Pré-requisitos:
* Compilador C (GCC ou Clang)
* Utilitário ```make```
* Processador com suporte a instruções AVX2
### Compilação
O ```Makefile``` customizado na raiz do projeto é usado para compilar as ferramentas. Os parâmetros de segurança ```ZKPOP_N``` e ```ZKPOP_TAU``` devem ser fornecidos durante a compilação.
**Importante**: Os executáveis ```gerar_prova``` e ```verificar_prova``` devem ser compilados com os mesmos parâmetros ```(N, Tau)``` para serem compatíveis.
```bash
# Para limpar compilações anteriores (recomendado ao trocar parâmetros)
make clean

# Exemplo: Compilar o gerador com N=921 e Tau=13
make ZKPOP_N=921 ZKPOP_TAU=13 gerar_prova

# Exemplo: Compilar o verificador com os mesmos parâmetros
make ZKPOP_N=921 ZKPOP_TAU=13 verificar_prova
```
### Execução das Ferramentas
Após a compilação, você pode usar as ferramentas da seguinte forma:
```bash
# 1. Gerar os artefatos (pk.bin, sk.bin, prova.bin)
./gerar_prova

# 2. Verificar a prova gerada
./verificar_prova
```
### Execução da Análise Completa
O script analise.sh automatiza todo o processo de compilação e teste para um conjunto predefinido de parâmetros ```(N, Tau)```.
```bash
# Dar permissão de execução (apenas na primeira vez)
chmod +x analise.sh

# Executar o script de análise
./analise.sh
```
Ao final da execução, o script gerará dois arquivos com os resultados:
* ```resultados_performance.csv```: Dados sobre tempo de geração e tamanho da prova.
* ```resultados_entropia.log```: Análise de entropia dos artefatos.
