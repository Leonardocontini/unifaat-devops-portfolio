# Análise — Docker Registry e IA no CI/CD

## 1. Escolha do Amazon ECR

O Amazon Elastic Container Registry (ECR) foi escolhido por ser o registry de imagens Docker da AWS. Ele permite armazenar, versionar e distribuir imagens para aplicações executadas em serviços como EC2 e ECS.

Em comparação com o Docker Hub e o GitHub Container Registry (GHCR), o ECR oferece integração direta com o ecossistema AWS, facilitando o uso das imagens nas próximas etapas do projeto.

O AWS Academy Learner Lab possui restrições de permissões IAM. Por isso, o projeto utiliza as credenciais temporárias da sessão do laboratório, sem criar usuários ou roles próprios. Essas credenciais precisam estar válidas no momento da publicação.

## 2. Estratégia de versionamento das imagens

O script `ecr-push.sh` utiliza três estratégias de identificação:

- **SHA:** identifica o commit que gerou a imagem, facilitando a rastreabilidade.
- **latest:** aponta para a versão publicada mais recentemente com essa tag.
- **SemVer:** utiliza versões como `1.2.3`, `1.2` e `1`, geradas a partir de uma tag Git no formato `v1.2.3`.

O SHA permite identificar uma versão específica do código. A tag `latest` facilita o uso cotidiano, mas não deve ser considerada uma referência imutável. As tags SemVer ajudam a organizar releases.

Para realizar rollback, pode-se baixar uma imagem usando uma tag de versão conhecida ou o SHA correspondente, em vez de depender de `latest`.

## 3. Padrões verificados pelo AI Review

O script `ai-review.js` analisa as linhas adicionadas ao diff do Pull Request e procura padrões potencialmente problemáticos.

| Padrão | Severidade | Motivo |
|---|---|---|
| Segredos hardcoded | CRITICAL | Risco de exposição de credenciais |
| Uso de `eval()` | CRITICAL | Possível execução de código não confiável |
| Possível SQL injection | CRITICAL | Risco de manipulação de consultas |
| `console.log()` | WARNING | Pode expor informações ou gerar logs desnecessários |
| `catch` vazio | WARNING | Pode ocultar erros |
| URLs externas | WARNING | Necessitam de verificação de segurança |
| Logs de variáveis de ambiente | CRITICAL | Podem expor credenciais |
| Verificação TLS desativada | CRITICAL | Reduz a segurança das conexões |
| Chaves AWS reconhecíveis | CRITICAL | Possível exposição de credenciais |

## 4. Lógica do quality gate

A análise gera um resultado em JSON com os achados classificados por severidade.

A regra de decisão é:

- **CRITICAL:** o script retorna código de saída diferente de zero e o workflow falha.
- **WARNING:** o workflow pode continuar, mas os achados devem ser revisados.
- **INFO:** o workflow pode continuar, mantendo os avisos informativos no relatório.

O workflow publica um comentário no Pull Request para apresentar os resultados. A etapa final aplica o quality gate e bloqueia a aprovação automática do job quando a análise encontra achados críticos ou falha ao executar.

A falha do job não garante, sozinha, que o GitHub impedirá o merge. Para isso, é necessário configurar uma regra de proteção da branch que exija a conclusão bem-sucedida desse workflow.

## 5. Prompt e lógica utilizados

A implementação inicial utiliza análise estática baseada em expressões regulares, sem chamar um modelo generativo externo.

A lógica segue estas instruções:

1. Ler o diff do Pull Request.
2. Examinar as linhas adicionadas.
3. Comparar cada linha com padrões conhecidos.
4. Classificar os possíveis problemas por severidade.
5. Gerar um relatório JSON.
6. Retornar código de erro quando houver achados CRITICAL.
7. Publicar o relatório no Pull Request.

Essa abordagem facilita a reprodução dos testes e não exige uma chave de API de IA. Entretanto, ela não interpreta completamente o contexto do código como um modelo generativo poderia fazer.

## 6. Quando confiar na análise e quando exigir revisão humana

A análise automatizada é útil para identificar rapidamente padrões conhecidos e aplicar regras consistentes em todos os Pull Requests.

Entretanto, os resultados devem ser considerados indicações para investigação, e não provas definitivas de vulnerabilidade ou de segurança.

A revisão humana continua necessária para avaliar a lógica de negócio, permissões, autenticação, autorização, arquitetura, dependências e contexto das consultas ao banco de dados.

Achados CRITICAL devem ser investigados antes do merge. Os WARNING também precisam ser avaliados, mesmo quando não bloqueiam o pipeline.

## 7. Limitações identificadas

A análise possui algumas limitações:

- Pode gerar falsos positivos ao identificar código que apenas se parece com um padrão inseguro.
- Pode deixar passar vulnerabilidades que não correspondem às expressões regulares.
- Analisa principalmente as linhas adicionadas, com contexto limitado do restante do projeto.
- Não executa testes dinâmicos nem comprova a explorabilidade de uma vulnerabilidade.
- A detecção de segredos não identifica todos os formatos de credenciais.
- O comentário do workflow apresenta achados, mas não substitui uma revisão completa do Pull Request.

Como melhoria futura, podem ser adicionadas ferramentas como Trivy, análise de dependências, testes automatizados e um modelo de IA com acesso controlado ao diff.

## 8. Conclusão

A integração do Amazon ECR com o GitHub Actions permite automatizar a publicação e a rastreabilidade das imagens Docker. O AI Review acrescenta uma verificação inicial de qualidade e segurança aos Pull Requests.

A combinação dessas ferramentas reduz tarefas manuais e ajuda a identificar problemas mais cedo, desde que os resultados sejam validados e que as regras de proteção do repositório estejam corretamente configuradas.
