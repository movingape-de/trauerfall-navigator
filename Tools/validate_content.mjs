#!/usr/bin/env node
/**
 * Prüft tasks_de.json und documents_de.json gegen das Schema, das die
 * Swift-Modelle erwarten. Läuft ohne Abhängigkeiten:
 *
 *   node Tools/validate_content.mjs
 *
 * Ziel: Content lässt sich pflegen, ohne dass ein Tippfehler erst in der
 * laufenden App auffällt.
 */

import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const contentDir = join(root, 'Danach', 'Content');

const PHASES = [1, 2, 3, 4];
const PLACES = ['home', 'hospital', 'care_home', 'elsewhere'];
const RELATIONSHIPS = ['spouse', 'partner', 'child', 'parent', 'other'];
const TRISTATE = ['yes', 'no', 'unknown'];
const DEADLINE_TYPES = ['relative', 'from_knowledge'];
const DEADLINE_UNITS = ['hours', 'days', 'business_days', 'months'];

const CONDITION_KEYS = {
  placeOfDeath: PLACES,
  relationship: RELATIONSHIPS,
  hasWill: TRISTATE,
  hasFuneralProvision: TRISTATE,
};

const errors = [];
const warnings = [];

const fail = (where, message) => errors.push(`${where}: ${message}`);
const warn = (where, message) => warnings.push(`${where}: ${message}`);

function readJSON(name) {
  try {
    return JSON.parse(readFileSync(join(contentDir, name), 'utf8'));
  } catch (error) {
    fail(name, `kann nicht gelesen werden – ${error.message}`);
    return null;
  }
}

function checkString(where, object, key, { required = true, min = 1 } = {}) {
  const value = object[key];
  if (value === undefined || value === null) {
    if (required) fail(where, `Feld "${key}" fehlt`);
    return;
  }
  if (typeof value !== 'string') return fail(where, `Feld "${key}" muss Text sein`);
  if (value.trim().length < min) fail(where, `Feld "${key}" ist zu kurz`);
}

function checkStringArray(where, object, key) {
  const value = object[key];
  if (value === undefined) return;
  if (!Array.isArray(value)) return fail(where, `Feld "${key}" muss eine Liste sein`);
  value.forEach((entry, index) => {
    if (typeof entry !== 'string' || entry.trim() === '') {
      fail(where, `"${key}"[${index}] ist kein sinnvoller Text`);
    }
  });
}

function checkConditions(where, conditions) {
  if (conditions === undefined) return;
  if (typeof conditions !== 'object' || conditions === null || Array.isArray(conditions)) {
    return fail(where, 'conditions muss ein Objekt sein');
  }
  for (const [key, values] of Object.entries(conditions)) {
    const allowed = CONDITION_KEYS[key];
    if (!allowed) {
      fail(where, `unbekannter Bedingungs-Schlüssel "${key}"`);
      continue;
    }
    if (!Array.isArray(values) || values.length === 0) {
      fail(where, `conditions.${key} muss eine nicht leere Liste sein`);
      continue;
    }
    for (const value of values) {
      if (!allowed.includes(value)) {
        fail(where, `conditions.${key} enthält unbekannten Wert "${value}"`);
      }
    }
    if (values.length === allowed.length) {
      warn(where, `conditions.${key} listet alle Werte auf – die Bedingung hat keine Wirkung`);
    }
  }
}

function checkDeadline(where, deadline) {
  if (deadline === undefined) return;
  if (typeof deadline !== 'object' || deadline === null) {
    return fail(where, 'deadline muss ein Objekt sein');
  }
  const type = deadline.type ?? 'relative';
  if (!DEADLINE_TYPES.includes(type)) {
    fail(where, `deadline.type "${type}" ist unbekannt`);
  }
  const unit = deadline.unit ?? 'days';
  if (!DEADLINE_UNITS.includes(unit)) {
    fail(where, `deadline.unit "${unit}" ist unbekannt`);
  }
  const amount = deadline.amount ?? deadline.days;
  if (typeof amount !== 'number' || !Number.isInteger(amount) || amount < 0) {
    fail(where, 'deadline braucht "amount" (oder "days") als ganze Zahl ab 0');
  }
  checkString(where, deadline, 'label');
  if (deadline.strict !== undefined && typeof deadline.strict !== 'boolean') {
    fail(where, 'deadline.strict muss true oder false sein');
  }
  if (deadline.strict === true && !deadline.note && type === 'from_knowledge') {
    warn(where, 'harte Frist ab Kenntnis ohne erklärende "note"');
  }
}

// ---------------------------------------------------------------- Aufgaben

const taskFile = readJSON('tasks_de.json');
let tasks = [];

if (taskFile) {
  if (typeof taskFile.version !== 'number') fail('tasks_de.json', '"version" fehlt');
  if (typeof taskFile.updated !== 'string') fail('tasks_de.json', '"updated" fehlt');
  if (!Array.isArray(taskFile.tasks)) {
    fail('tasks_de.json', '"tasks" muss eine Liste sein');
  } else {
    tasks = taskFile.tasks;
  }
}

const taskIDs = new Set();
const priorityByPhase = new Map();

for (const [index, task] of tasks.entries()) {
  const where = `Aufgabe ${task?.id ?? `#${index}`}`;
  if (typeof task !== 'object' || task === null) {
    fail(where, 'ist kein Objekt');
    continue;
  }

  checkString(where, task, 'id');
  if (typeof task.id === 'string') {
    if (!/^[a-z0-9_]+$/.test(task.id)) {
      fail(where, 'id darf nur Kleinbuchstaben, Ziffern und _ enthalten');
    }
    if (taskIDs.has(task.id)) fail(where, 'id ist doppelt vergeben');
    taskIDs.add(task.id);
  }

  if (!PHASES.includes(task.phase)) fail(where, `phase "${task.phase}" ist ungültig`);

  checkString(where, task, 'title');
  checkString(where, task, 'summary', { min: 10 });
  checkString(where, task, 'details', { min: 40 });
  checkStringArray(where, task, 'documents');
  checkStringArray(where, task, 'contacts');
  checkStringArray(where, task, 'tips');
  checkDeadline(where, task.deadline);
  checkConditions(where, task.conditions);

  if (task.priority !== undefined && !Number.isInteger(task.priority)) {
    fail(where, 'priority muss eine ganze Zahl sein');
  }

  if (typeof task.summary === 'string' && task.summary.length > 140) {
    warn(where, `summary ist ${task.summary.length} Zeichen lang – in der Liste wird das eng`);
  }
  if (typeof task.title === 'string' && task.title.length > 60) {
    warn(where, `title ist ${task.title.length} Zeichen lang`);
  }
  if (/\bdu\b|\bdein/i.test(`${task.title} ${task.summary} ${task.details}`)) {
    warn(where, 'enthält möglicherweise eine Du-Anrede – die App siezt durchgängig');
  }

}

// -------------------------------------------------------------- Dokumente

const documentFile = readJSON('documents_de.json');
let documents = [];

if (documentFile) {
  if (!Array.isArray(documentFile.documents)) {
    fail('documents_de.json', '"documents" muss eine Liste sein');
  } else {
    documents = documentFile.documents;
  }
}

const documentIDs = new Set();

for (const [index, doc] of documents.entries()) {
  const where = `Dokument ${doc?.id ?? `#${index}`}`;
  checkString(where, doc, 'id');
  if (typeof doc.id === 'string') {
    if (documentIDs.has(doc.id)) fail(where, 'id ist doppelt vergeben');
    documentIDs.add(doc.id);
  }
  checkString(where, doc, 'title');
  checkString(where, doc, 'purpose', { min: 10 });
  checkString(where, doc, 'source');
  checkString(where, doc, 'recommended_count', { required: false });
  checkStringArray(where, doc, 'used_for');
  checkConditions(where, doc.conditions);
  if (doc.priority !== undefined && !Number.isInteger(doc.priority)) {
    fail(where, 'priority muss eine ganze Zahl sein');
  }
}

// ------------------------------------------------------ Abdeckung prüfen

const combinations = [];
for (const place of PLACES) {
  for (const relationship of RELATIONSHIPS) {
    for (const hasWill of TRISTATE) {
      for (const hasFuneralProvision of TRISTATE) {
        combinations.push({ placeOfDeath: place, relationship, hasWill, hasFuneralProvision });
      }
    }
  }
}

const matches = (conditions, profile) => {
  if (!conditions) return true;
  return Object.entries(conditions).every(([key, values]) => values.includes(profile[key]));
};

let minVisible = Infinity;
let worstProfile = null;
const phaseMinimums = new Map(PHASES.map((phase) => [phase, Infinity]));
const reportedPriorityClashes = new Set();

for (const profile of combinations) {
  const visible = tasks.filter((task) => matches(task.conditions, profile));
  if (visible.length < minVisible) {
    minVisible = visible.length;
    worstProfile = profile;
  }
  for (const phase of PHASES) {
    const inPhase = visible.filter((task) => task.phase === phase);
    if (inPhase.length < phaseMinimums.get(phase)) phaseMinimums.set(phase, inPhase.length);

    // Gleiche Priorität stört nur, wenn beide Aufgaben demselben Nutzer
    // gleichzeitig angezeigt werden – sonst schließen die Bedingungen sie aus.
    const seen = new Map();
    for (const task of inPhase) {
      const prio = task.priority ?? 100;
      if (seen.has(prio)) {
        const clash = [seen.get(prio), task.id].sort().join(' / ');
        if (!reportedPriorityClashes.has(clash)) {
          reportedPriorityClashes.add(clash);
          warn('Reihenfolge', `Phase ${phase}: gleiche priority ${prio} bei ${clash}`);
        }
      } else {
        seen.set(prio, task.id);
      }
    }
  }
}

// Solange der Katalog noch im Aufbau ist, sind Lücken erwartbar.
const catalogComplete = tasks.length >= 40;
const report = catalogComplete ? fail : warn;

for (const phase of PHASES) {
  if (phaseMinimums.get(phase) === 0) {
    report('Abdeckung', `Phase ${phase} ist für mindestens ein Profil komplett leer`);
  }
}
if (!catalogComplete) {
  warn('Abdeckung', `nur ${tasks.length} Aufgaben – Zielgröße sind 40 bis 60`);
}

// ------------------------------------------------------------- Ausgabe

const phaseCounts = PHASES.map(
  (phase) => `Phase ${phase}: ${tasks.filter((task) => task.phase === phase).length}`
);

console.log('Danach – Content-Prüfung');
console.log('─'.repeat(52));
console.log(`Aufgaben gesamt: ${tasks.length}  (${phaseCounts.join(', ')})`);
console.log(`Dokumente gesamt: ${documents.length}`);
console.log(`Profile geprüft: ${combinations.length}`);
console.log(
  `Wenigste sichtbare Aufgaben: ${minVisible} bei ${JSON.stringify(worstProfile)}`
);
console.log(
  `Aufgaben mit Frist: ${tasks.filter((task) => task.deadline).length}, ` +
    `davon hart: ${tasks.filter((task) => task.deadline?.strict).length}`
);

if (warnings.length) {
  console.log(`\nHinweise (${warnings.length}):`);
  for (const message of warnings) console.log(`  · ${message}`);
}

if (errors.length) {
  console.log(`\nFehler (${errors.length}):`);
  for (const message of errors) console.log(`  ✗ ${message}`);
  process.exit(1);
}

console.log('\nAlles in Ordnung.');
