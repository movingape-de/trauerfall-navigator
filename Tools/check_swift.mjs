// Prüft alle Swift-Dateien auf Syntaxfehler, ohne Xcode und ohne macOS.
// Fängt Syntax, keine Typfehler – dafür braucht es einen echten Compiler.
//
//   cd Tools && npm install && npm run check:swift

import Parser from 'tree-sitter';
import Swift from 'tree-sitter-swift';
import { readFileSync } from 'node:fs';
import { execSync } from 'node:child_process';

const root = process.argv[2];
const files = execSync(`find ${root} -name '*.swift' | sort`, { encoding: 'utf8' })
  .trim().split('\n').filter(Boolean);

const parser = new Parser();
parser.setLanguage(Swift);

let problems = 0;

for (const file of files) {
  const source = readFileSync(file, 'utf8');
  const tree = parser.parse(source);
  const found = [];

  const walk = (node) => {
    if (node.type === 'ERROR' || node.isMissing) {
      found.push({
        type: node.isMissing ? 'MISSING' : 'ERROR',
        line: node.startPosition.row + 1,
        col: node.startPosition.column + 1,
        text: source.split('\n')[node.startPosition.row]?.trim().slice(0, 90) ?? '',
      });
      return; // nicht weiter absteigen, sonst Rauschen
    }
    for (let i = 0; i < node.childCount; i++) walk(node.child(i));
  };
  walk(tree.rootNode);

  const short = file.replace(root + '/', '');
  if (found.length) {
    problems += found.length;
    console.log(`\n✗ ${short}`);
    for (const f of found) {
      console.log(`   ${f.type} Zeile ${f.line}:${f.col}  ${f.text}`);
    }
  } else {
    console.log(`✓ ${short}`);
  }
}

console.log(`\n${files.length} Dateien geparst, ${problems} Syntaxprobleme.`);
process.exit(problems ? 1 : 0);
