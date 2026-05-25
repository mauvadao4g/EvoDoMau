# 🚀 EvoDoMau - Evolution API Auto-Installer

Este repositório contém scripts automatizados para a instalação e configuração da **Evolution API (v2.2.3)** em ambientes Linux (Ubuntu/Debian). O projeto facilita o deploy completo, incluindo banco de dados, cache e segurança SSL.

## 🛠️ Funcionalidades

- **Instalação Automatizada:** Configura Docker e Docker Compose do zero.
- **Stack Completa:**
  - Evolution API v2.2.3
  - PostgreSQL 15 (Banco de dados)
  - Redis 7 (Cache para performance)
- **Segurança e SSL:** Script dedicado para configurar Nginx como Proxy Reverso e Certbot para certificados SSL gratuitos (Let's Encrypt).
- **Configuração Interativa:** Permite definir Token Global e Chave da OpenAI durante a instalação.
- **Auto-Gerenciamento:** Opção de limpeza total do Docker para instalações em VPS virgens.

## 📋 Pré-requisitos

- Servidor Linux (Recomendado Ubuntu 22.04 LTS ou superior).
- Acesso Root ou usuário com privilégios sudo.
- Um domínio ou subdomínio apontado para o IP do servidor (para o SSL).

## 🚀 Como Instalar

## Install Inline
```bash
bash <(wget -qO- https://raw.githubusercontent.com/mauvadao4g/EvoDoMau/refs/heads/main/install.sh)
```

### 1. Clonar o Repositório
```bash
git clone https://github.com/MAUVADAO/EvoDoMau.git
cd EvoDoMau
chmod +x *.sh
```

### 2. Instalar a Evolution API
Execute o script principal e siga as instruções na tela:
```bash
./evoInstall.sh
```
*O script irá perguntar se deseja uma limpeza total do Docker e solicitará seu Token Global e Chave OpenAI.*

### 3. Configurar SSL (HTTPS)
Após a instalação da API, configure o domínio e o certificado SSL:
```bash
./setup_ssl.sh
```
*Informe o seu domínio (ex: api.meusite.com) e um e-mail válido para o registro do certificado.*

## 📂 Localização dos Dados

- **Diretório da Instalação:** `/opt/evolution-api`
- **Arquivo de Credenciais:** As chaves geradas e configurações do banco são salvas em `/opt/evolution-api/credenciais.txt`.

## 🛡️ Segurança
Os scripts geram senhas aleatórias e seguras para o PostgreSQL e Redis automaticamente, garantindo que sua instalação não utilize credenciais padrão.

---
Desenvolvido por **MAUVADAO** 🖥️
