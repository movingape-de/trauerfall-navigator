import Parser from 'tree-sitter';
import Swift from 'tree-sitter-swift';
import { readFileSync } from 'node:fs';
import { execSync } from 'node:child_process';

const root = process.argv[2];
const files = execSync(`find ${root} -name '*.swift' | sort`, { encoding: 'utf8' })
  .trim().split('\n').filter(Boolean);

const parser = new Parser();
parser.setLanguage(Swift);

// Typen, die aus SDKs kommen und deshalb nicht im Projekt deklariert sind.
const SDK = new Set(`
String Int Double Bool Date Data URL UUID Error Void Any AnyObject Set Array Dictionary
Optional Result Task Calendar DateComponents DateFormatter Locale TimeZone Bundle
Decodable Encodable Codable Hashable Equatable Identifiable Comparable Sendable
CaseIterable RawRepresentable ObservableObject CustomStringConvertible
Decoder Encoder DecodingError EncodingError CodingKey KeyedDecodingContainer
CGFloat UIColor UIUserInterfaceStyle UITraitCollection
View Text Image Button Toggle Picker DatePicker TextField TextEditor Divider Spacer
VStack HStack ZStack LazyVStack ScrollView List Section Form Group NavigationStack
NavigationLink TabView Menu Label Color Font Capsule Rectangle RoundedRectangle
GeometryReader ProgressView ContentUnavailableView LabeledContent EmptyView
ButtonStyle ViewModifier ButtonStyleConfiguration ScaledMetric Binding State
StateObject EnvironmentObject Environment Bindable Query ObservedObject FocusState
ToolbarItem ToolbarItemGroup App Scene WindowGroup PreviewProvider
Model ModelContainer ModelContext ModelConfiguration Schema Attribute
Product Transaction AppStore StoreKit VerificationResult
UNUserNotificationCenter UNMutableNotificationContent UNNotificationRequest
UNCalendarNotificationTrigger UNAuthorizationStatus UNNotificationSettings
`.trim().split(/\s+/));

const declared = new Map();   // Name -> Datei
const used = new Map();       // Name -> Set(Datei:Zeile)
const trees = [];

const DECL_TYPES = new Set([
  'class_declaration', 'protocol_declaration', 'typealias_declaration',
]);

for (const file of files) {
  const source = readFileSync(file, 'utf8');
  const tree = parser.parse(source);
  trees.push({ file, source, tree });

  const walk = (node) => {
    // tree-sitter-swift nutzt class_declaration auch für struct/enum/extension.
    if (DECL_TYPES.has(node.type)) {
      const name = node.childForFieldName('name');
      if (name && /^[A-Z]/.test(name.text)) {
        if (!declared.has(name.text)) declared.set(name.text, file);
      }
    }
    for (let i = 0; i < node.childCount; i++) walk(node.child(i));
  };
  walk(tree.rootNode);
}

for (const { file, tree } of trees) {
  const walk = (node) => {
    if (node.type === 'type_identifier' || node.type === 'simple_identifier') {
      const t = node.text;
      if (/^[A-Z][A-Za-z0-9_]*$/.test(t)) {
        if (!used.has(t)) used.set(t, new Set());
        used.get(t).add(`${file.replace(root + '/', '')}:${node.startPosition.row + 1}`);
      }
    }
    for (let i = 0; i < node.childCount; i++) walk(node.child(i));
  };
  walk(tree.rootNode);
}

const unknown = [...used.entries()]
  .filter(([name]) => !declared.has(name) && !SDK.has(name))
  .sort();

const unusedDecls = [...declared.keys()].filter((name) => {
  const sites = used.get(name);
  if (!sites) return true;
  // Nur die eigene Deklarationszeile? Dann wird der Typ nirgends verwendet.
  return sites.size <= 1;
});

console.log(`Deklarierte Typen im Projekt: ${declared.size}`);
console.log(`Großgeschriebene Bezeichner insgesamt: ${used.size}`);

if (unknown.length) {
  console.log(`\nNicht im Projekt deklariert und nicht in der SDK-Liste (${unknown.length}):`);
  for (const [name, sites] of unknown) {
    const list = [...sites].slice(0, 3).join(', ');
    console.log(`  ${name.padEnd(30)} ${list}${sites.size > 3 ? ` (+${sites.size - 3})` : ''}`);
  }
  console.log('\nDas ist eine Prüfliste, keine Fehlerliste: Alles, was zu Apples SDK');
  console.log('gehört, ist in Ordnung. Zu prüfen sind nur eigene Namen.');
}

if (unusedDecls.length) {
  console.log(`\nDeklariert, aber nirgends sonst verwendet (${unusedDecls.length}):`);
  for (const name of unusedDecls) console.log(`  ${name}  (${declared.get(name).replace(root + '/', '')})`);
}
