# Contributing to SoftWave Infrastructure

Obrigado por considerar contribuir com o SoftWave Infrastructure! 🎉

## 📋 Índice

- [Código de Conduta](#código-de-conduta)
- [Como Posso Contribuir?](#como-posso-contribuir)
- [Guia de Desenvolvimento](#guia-de-desenvolvimento)
- [Padrões de Commit](#padrões-de-commit)
- [Pull Request Process](#pull-request-process)

## 📜 Código de Conduta

Este projeto e todos os participantes devem aderir a um código de conduta respeitoso. Ao participar, espera-se que você mantenha esse código. Por favor, reporte comportamentos inaceitáveis.

## 🤝 Como Posso Contribuir?

### Reportando Bugs

Antes de criar um bug report, verifique se já existe uma issue similar. Se encontrar uma, adicione um comentário em vez de abrir uma nova issue.

Ao criar um bug report, inclua:

- **Título descritivo**
- **Passos para reproduzir** o problema
- **Comportamento esperado** vs **comportamento atual**
- **Screenshots** se aplicável
- **Versão do Docker** e **Docker Compose**
- **Sistema operacional**

### Sugerindo Melhorias

Sugestões de melhorias são sempre bem-vindas! Crie uma issue incluindo:

- **Descrição clara** da melhoria
- **Por que** essa melhoria seria útil
- **Como** você imagina que funcionaria
- **Exemplos** se possível

### Contribuindo com Código

1. **Fork** o repositório
2. **Clone** seu fork localmente
3. **Crie uma branch** para sua feature (`git checkout -b feature/AmazingFeature`)
4. **Faça suas mudanças**
5. **Teste suas mudanças**
6. **Commit** suas mudanças
7. **Push** para a branch (`git push origin feature/AmazingFeature`)
8. **Abra um Pull Request**

## 🔧 Guia de Desenvolvimento

### Setup do Ambiente

```bash
# Clone o repositório
git clone https://github.com/SoftWave-SPTech/softwave-infra.git
cd softwave-infra

# Inicialize o ambiente
./init.sh

# Inicie os serviços
./start.sh
```

### Testando Suas Mudanças

Antes de submeter um PR, certifique-se de:

1. **Testar localmente**
```bash
# Teste o ambiente completo
docker compose up
```

2. **Verificar scripts**
```bash
# Teste todos os scripts shell
./init.sh
./start.sh
./stop.sh
./backup.sh
```

3. **Testar em diferentes ambientes** (se possível)
   - Linux
   - macOS
   - Windows (WSL)

### Padrões de Código

#### Shell Scripts

- Use `#!/bin/bash` no início
- Adicione comentários descritivos
- Use `set -e` para parar em erros
- Valide entrada do usuário
- Forneça mensagens de erro claras
- Use funções para código reutilizável

Exemplo:
```bash
#!/bin/bash
set -e

# Function to print error messages
print_error() {
    echo -e "\033[0;31m✗ $1\033[0m"
}

# Validate input
if [ -z "$1" ]; then
    print_error "Missing required argument"
    exit 1
fi
```

#### Docker

- Use imagens Alpine quando possível
- Multi-stage builds para otimização
- Não rode como root
- Inclua health checks
- Use .dockerignore

#### Docker Compose

- Use versão 3.8+
- Nomeie os serviços claramente
- Configure health checks
- Use named volumes
- Documente variáveis de ambiente

#### YAML/JSON

- Use indentação de 2 espaços
- Mantenha consistência
- Adicione comentários quando necessário

### Estrutura de Diretórios

```
softwave-infra/
├── .github/
│   └── workflows/          # GitHub Actions
├── cloud/
│   ├── aws/               # Configs AWS
│   ├── azure/             # Configs Azure
│   └── gcp/               # Configs GCP
├── scripts/               # Scripts SQL
├── nginx/                 # Configs Nginx
├── *.sh                   # Shell scripts
└── *.yml                  # Docker Compose files
```

## 📝 Padrões de Commit

Usamos [Conventional Commits](https://www.conventionalcommits.org/) para mensagens de commit:

### Formato

```
<tipo>[escopo opcional]: <descrição>

[corpo opcional]

[rodapé(s) opcional(is)]
```

### Tipos

- `feat`: Nova feature
- `fix`: Correção de bug
- `docs`: Mudanças na documentação
- `style`: Formatação, ponto e vírgula, etc
- `refactor`: Refatoração de código
- `perf`: Melhoria de performance
- `test`: Adição/correção de testes
- `chore`: Mudanças em builds, configs, etc

### Exemplos

```bash
# Feature
git commit -m "feat: add backup scheduling support"

# Bug fix
git commit -m "fix: correct database connection timeout"

# Documentation
git commit -m "docs: update README with new examples"

# Refactoring
git commit -m "refactor: simplify init.sh script logic"
```

### Mensagens Descritivas

- Use o imperativo: "add" não "added" ou "adds"
- Primeira linha com no máximo 72 caracteres
- Referencie issues quando aplicável: `fixes #123`
- Seja descritivo no corpo do commit se necessário

## 🔄 Pull Request Process

### Antes de Submeter

- [ ] Teste suas mudanças localmente
- [ ] Atualize a documentação se necessário
- [ ] Adicione/atualize comentários no código
- [ ] Siga os padrões de código
- [ ] Verifique se não quebrou funcionalidades existentes

### Processo de Review

1. **Crie o PR** com título descritivo
2. **Descreva** suas mudanças claramente
3. **Link** issues relacionadas
4. **Aguarde review** de um maintainer
5. **Responda** a comentários e faça ajustes
6. **Merge** será feito após aprovação

### Template de PR

```markdown
## Descrição
[Descrição clara das mudanças]

## Tipo de Mudança
- [ ] Bug fix
- [ ] Nova feature
- [ ] Breaking change
- [ ] Documentação

## Checklist
- [ ] Testei minhas mudanças
- [ ] Atualizei a documentação
- [ ] Segui os padrões de código
- [ ] Adicionei comentários quando necessário

## Issues Relacionadas
Closes #[número da issue]
```

## 📚 Recursos Úteis

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Shell Scripting Guide](https://google.github.io/styleguide/shellguide.html)
- [Conventional Commits](https://www.conventionalcommits.org/)

## ❓ Dúvidas?

Se você tiver dúvidas sobre como contribuir:

- Abra uma [issue](https://github.com/SoftWave-SPTech/softwave-infra/issues) com a tag `question`
- Entre em contato com os maintainers

## 🎉 Obrigado!

Sua contribuição é muito valorizada! Cada PR, issue ou sugestão ajuda a melhorar o projeto para todos. 🚀

## 👥 Maintainers

- [@SoftWave-SPTech](https://github.com/SoftWave-SPTech)

---

*Happy Contributing!* 💻✨
