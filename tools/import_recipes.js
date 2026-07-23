/**
 * Import recipes.json (from export_firestore.js) into Supabase.
 *
 *   npm install @supabase/supabase-js
 *   $env:SUPABASE_URL="https://xxxx.supabase.co"
 *   $env:SUPABASE_SECRET_KEY="sb_secret_..."   # secret key — server side only
 *   $env:AUTHOR_ID="<your admin profile uuid>"
 *
 *   node import_recipes.js            # dry run (default)
 *   node import_recipes.js --report   # show fragments the dictionary missed
 *   node import_recipes.js --write    # actually insert
 *
 * The legacy strings are damaged (missing commas, typos), so parsing works by
 * finding KNOWN ingredients inside each fragment rather than trusting the text.
 */
const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
const { PANTRY, CORE, JUNK } = require('./ingredients_dictionary.js');

const WRITE = process.argv.includes('--write');
const REPORT = process.argv.includes('--report');

// longest first so "coconut milk" beats "milk", "cumin seeds" beats "cumin"
const VOCAB = [...PANTRY, ...CORE].sort((a, b) => b.length - a.length);
const PANTRY_SET = new Set(PANTRY);

// ---------------------------------------------------------------- text tidy
const UNITS = 'cups?|teaspoons?|tablespoons?|tsp|tbsp|grams?|gms?|kg|ml|litres?|liters?|inch(?:es)?|sprigs?|spr|pinch(?:es)?|handfuls?|pieces?|cloves?|bunch(?:es)?|nos?|packets?|cans?';

function tidy(raw) {
  return String(raw)
    .toLowerCase()
    .replace(/\([^)]*\)/g, ' ')                       // (Semolina/ Rava)
    .replace(/[^a-z\s]/g, ' ')                        // digits, slashes, punctuation
    .replace(new RegExp(`\\b(?:${UNITS})\\b`, 'g'), ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Pull every known ingredient out of a fragment. */
function extractKnown(text) {
  let s = ` ${text} `;
  const found = [];
  for (const name of VOCAB) {
    const needle = ` ${name} `;
    if (s.includes(needle)) {
      found.push(name);
      s = s.split(needle).join(' ');                  // consume so shorter names don't re-match
    }
  }
  return { found, leftover: s.trim() };
}

const missed = new Map();

function parseIngredients(str) {
  if (!str) return [];
  const names = new Set();
  // split on commas AND the word "and" — merged fragments are common here
  const fragments = String(str).split(/,| and /i);

  for (const frag of fragments) {
    const text = tidy(frag);
    if (!text) continue;
    const { found, leftover } = extractKnown(text);
    found.forEach((f) => names.add(f));

    // track what the dictionary could not explain, for --report
    for (const word of leftover.split(' ')) {
      if (word.length > 2 && !JUNK.has(word)) {
        missed.set(word, (missed.get(word) || 0) + 1);
      }
    }
  }
  return [...names];
}

// ------------------------------------------------------------------ main
(async () => {
  const rows = JSON.parse(fs.readFileSync(path.join(__dirname, 'recipes.json'), 'utf8'));

  // ---- report mode: no DB needed
  if (REPORT) {
    rows.forEach((r) => parseIngredients(r.recipe_ingredients));
    const top = [...missed.entries()].sort((a, b) => b[1] - a[1]).slice(0, 60);
    console.log('Most common words the dictionary did NOT recognise:\n');
    top.forEach(([w, n]) => console.log(`  ${String(n).padStart(5)}  ${w}`));
    console.log('\nAdd the real ingredients from this list to ingredients_dictionary.js,');
    console.log('then re-run. Ignore typos and stray words.');
    process.exit(0);
  }

  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SECRET_KEY = process.env.SUPABASE_SECRET_KEY;
  const AUTHOR_ID = process.env.AUTHOR_ID;
  if (!SUPABASE_URL || !SECRET_KEY || !AUTHOR_ID) {
    console.error('Set SUPABASE_URL, SUPABASE_SECRET_KEY and AUTHOR_ID first.');
    process.exit(1);
  }
  const db = createClient(SUPABASE_URL, SECRET_KEY);

  console.log(`Loaded ${rows.length} recipes. ${WRITE ? 'WRITING' : 'DRY RUN'}\n`);

  const catCache = new Map();
  const ingCache = new Map();

  async function ensureCategory(name) {
    const clean = (name || 'Uncategorized').trim();
    if (catCache.has(clean)) return catCache.get(clean);
    const found = await db.from('categories').select('id').eq('name', clean).maybeSingle();
    let id = found.data?.id;
    if (!id) {
      const kind = /juice|drink|beverage|smoothie|shake|tea|coffee/i.test(clean) ? 'beverage' : 'food';
      const ins = await db.from('categories').insert({ name: clean, kind }).select('id').single();
      if (ins.error) throw ins.error;
      id = ins.data.id;
    }
    catCache.set(clean, id);
    return id;
  }

  async function ensureIngredient(name) {
    if (ingCache.has(name)) return ingCache.get(name);
    const found = await db.from('ingredients').select('id').eq('name', name).maybeSingle();
    let id = found.data?.id;
    if (!id) {
      const ins = await db.from('ingredients')
        .insert({ name, is_pantry: PANTRY_SET.has(name) }).select('id').single();
      if (ins.error) throw ins.error;
      id = ins.data.id;
    }
    ingCache.set(name, id);
    return id;
  }

  let ok = 0, skipped = 0, noIng = 0;

  for (const [i, r] of rows.entries()) {
    const title = (r.recipe_name || '').trim();
    if (!title) { skipped++; continue; }

    const names = parseIngredients(r.recipe_ingredients);
    const core = names.filter((n) => !PANTRY_SET.has(n));
    if (core.length === 0) noIng++;

    if (!WRITE) {
      if (i < 6) {
        console.log(title);
        console.log(`   course : ${r.recipe_course || '-'}`);
        console.log(`   cuisine: ${r.recipe_category || '-'}`);
        console.log(`   core   : ${core.join(', ') || '(none)'}`);
        console.log(`   pantry : ${names.filter((n) => PANTRY_SET.has(n)).join(', ') || '-'}\n`);
      }
      ok++;
      continue;
    }

    try {
      const categoryId = await ensureCategory(r.recipe_course);
      const ins = await db.from('recipes').insert({
        title,
        instructions: r.recipe_description || null,
        image_url: r.recipeImageURL || null,
        cook_time: r.recipe_time || null,
        diet: r.recipe_diet || null,
        cuisine: r.recipe_category || null,
        category_id: categoryId,
        author_id: AUTHOR_ID,
        status: 'approved',
      }).select('id').single();
      if (ins.error) throw ins.error;

      for (const name of names) {
        const ingId = await ensureIngredient(name);
        await db.from('recipe_ingredients').upsert({
          recipe_id: ins.data.id,
          ingredient_id: ingId,
          role: 'core',           // is_pantry on the ingredient controls matching
        });
      }
      ok++;
      if (ok % 50 === 0) console.log(`  ...${ok} imported`);
    } catch (e) {
      skipped++;
      console.log(`x failed: ${title} — ${e.message}`);
    }
  }

  console.log(`\nDone. ok=${ok} skipped=${skipped} recipesWithNoCoreIngredients=${noIng}`);
  if (!WRITE) console.log('Dry run only. Re-run with --write to insert.');
  process.exit(0);
})();
