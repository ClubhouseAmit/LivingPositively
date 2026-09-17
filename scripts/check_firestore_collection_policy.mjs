import { readdirSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join, relative } from 'node:path';

const repositoryRoot = join(fileURLToPath(new URL('.', import.meta.url)), '..');

function serverOnlyCollectionsFromRules(rulesPath) {
  const rules = readFileSync(rulesPath, 'utf8');
  const match = rules.match(
    /function serverOnlyCollection\(collectionId\)\s*\{([\s\S]*?)\n\s*\}/,
  );
  if (match == null) {
    throw new Error(
      `Unable to find serverOnlyCollection in ${relative(process.cwd(), rulesPath)}`,
    );
  }
  return new Set([...match[1].matchAll(/"([^"\\]+)"/g)].map((entry) => entry[1]));
}

// Values constrained by the provisioner or scheduler schema rather than a
// literal collection call.
const approvedDynamicExpressions = new Set([
  'collectionName',
  'document.collection',
  'collection',
]);

function sourceFiles(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return sourceFiles(path);
    return entry.name.endsWith('.ts') && !entry.name.endsWith('.test.ts')
      ? [path]
      : [];
  });
}

export function findUnclassifiedCollectionReferences(
  sourceRoot,
  rulesPath = join(process.cwd(), 'firestore.rules'),
) {
  const serverOnlyCollections = serverOnlyCollectionsFromRules(rulesPath);
  const issues = [];
  for (const file of sourceFiles(sourceRoot)) {
    const source = readFileSync(file, 'utf8');
    const relativePath = relative(process.cwd(), file).replaceAll('\\', '/');
    for (const match of source.matchAll(/\.collection\(([^)]+)\)/g)) {
      const expression = match[1].trim();
      const literal = expression.match(/^['"]([^'"]+)['"]$/)?.[1];
      if (literal != null) {
        if (!serverOnlyCollections.has(literal) && !literal.startsWith('quotes_')) {
          issues.push(`${relativePath}: unclassified collection ${literal}`);
        }
      } else if (!approvedDynamicExpressions.has(expression)) {
        issues.push(`${relativePath}: unclassified dynamic collection ${expression}`);
      }
    }
  }
  return issues;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const issues = findUnclassifiedCollectionReferences(
    join(repositoryRoot, 'functions/src'),
    join(repositoryRoot, 'firestore.rules'),
  );
  if (issues.length > 0) {
    for (const issue of issues) console.error(`::error::${issue}`);
    process.exitCode = 1;
  }
}
