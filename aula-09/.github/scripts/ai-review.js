
const fs = require("fs");

const diffPath = process.argv[2];

if (!diffPath || !fs.existsSync(diffPath)) {
  console.error("Uso: node ai-review.js <arquivo-diff>");
  process.exit(2);
}

const diff = fs.readFileSync(diffPath, "utf8");
const findings = [];

function check(pattern, severity, title, description) {
  const lines = diff.split("\n");

  lines.forEach((line, index) => {
    // Analisa somente linhas adicionadas no diff.
    if (!line.startsWith("+") || line.startsWith("+++")) return;

    const code = line.slice(1);

    if (pattern.test(code)) {
      findings.push({
        severity,
        title,
        description,
        line: index + 1,
        code: code.trim().slice(0, 160),
      });
    }
  });
}

// 1. Possíveis credenciais hardcoded
check(
  /(?:password|passwd|secret|api[_-]?key|access[_-]?token)\s*[:=]\s*["'][^"']{4,}["']/i,
  "CRITICAL",
  "Possível segredo hardcoded",
  "Verifique se há credenciais ou tokens diretamente no código."
);

// 2. Uso de eval()
check(
  /\beval\s*\(/,
  "CRITICAL",
  "Uso de eval()",
  "eval() pode executar código não confiável."
);

// 3. Possível SQL injection
check(
  /(?:query|execute)\s*\(\s*["'`].*\$\{|(?:query|execute)\s*\([^)]*\+\s*[a-z_$]/i,
  "CRITICAL",
  "Possível SQL injection",
  "Verifique se entradas são concatenadas na consulta SQL."
);

// 4. console.log
check(
  /\bconsole\.log\s*\(/,
  "WARNING",
  "console.log encontrado",
  "Remova logs desnecessários antes de publicar em produção."
);

// 5. catch vazio
check(
  /catch\s*(?:\([^)]*\)\s*)?\{\s*\}/,
  "WARNING",
  "catch vazio",
  "Trate ou registre o erro para evitar falhas silenciosas."
);

// 6. Uso de HTTP sem TLS
check(
  /https?:\/\/(?!localhost\b|127\.0\.0\.1\b)[\w.-]+/i,
  "WARNING",
  "URL HTTP/HTTPS no código",
  "Confira se serviços externos usam HTTPS e se a URL não contém dados sensíveis."
);

// 7. Possível exposição de variáveis de ambiente
check(
  /console\.(?:log|error|warn)\s*\([^)]*process\.env/i,
  "CRITICAL",
  "Possível exposição de variável de ambiente",
  "Evite imprimir variáveis de ambiente, pois podem conter segredos."
);

// 8. Desativação de verificação TLS
check(
  /rejectUnauthorized\s*:\s*false|NODE_TLS_REJECT_UNAUTHORIZED\s*=\s*["']?0/i,
  "CRITICAL",
  "Verificação TLS desativada",
  "Desativar a validação TLS pode permitir conexões inseguras."
);

// 9. Uso de credenciais AWS no código
check(
  /AKIA[0-9A-Z]{16}/,
  "CRITICAL",
  "Possível chave AWS exposta",
  "Remova a chave e faça a rotação das credenciais imediatamente, se for real."
);

const counts = {
  CRITICAL: findings.filter((f) => f.severity === "CRITICAL").length,
  WARNING: findings.filter((f) => f.severity === "WARNING").length,
  INFO: findings.filter((f) => f.severity === "INFO").length,
};

const result = {
  findings,
  counts,
  gate: counts.CRITICAL > 0 ? "BLOCKED" : "PASSED",
};

console.log(JSON.stringify(result, null, 2));

// O workflow usará esse código de saída para aplicar o quality gate.
if (counts.CRITICAL > 0) {
  process.exitCode = 1;
}
