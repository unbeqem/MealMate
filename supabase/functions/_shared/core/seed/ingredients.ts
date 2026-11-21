import type { Aisle, Allergen, BaseUnit, DietClass, Ingredient } from '../types.ts';

type Extra = Partial<Pick<Ingredient, 'gramsPerPiece' | 'densityGPerMl' | 'unitWeights' | 'shelfLifeDays' | 'isStaple'>> & {
  aliases?: string[];
};

function I(
  id: string,
  name: string,
  baseUnit: BaseUnit,
  aisle: Aisle,
  dietClass: DietClass,
  allergens: Allergen[],
  packs: [number, string][],
  extra: Extra = {},
): Ingredient {
  const { aliases = [], ...rest } = extra;
  return {
    id,
    name,
    aliases,
    baseUnit,
    aisle,
    dietClass,
    allergens,
    packages: packs.map(([amount, label]) => ({ id: `${id}-${amount}`, amount, label })),
    ...rest,
  };
}

const V = 'vegan' as const;
const VEG = 'vegetarian' as const;
const FISH = 'pescetarian' as const;
const MEAT = 'meat' as const;
const STAPLE: Extra = { isStaple: true };

export const INGREDIENTS: Ingredient[] = [
  // Obst & Gemüse
  I('blattspinat', 'Blattspinat', 'g', 'obst_gemuese', V, [], [[450, 'Beutel 450 g']], { aliases: ['Spinat', 'frischer Spinat'], shelfLifeDays: 3 }),
  I('babyspinat', 'Babyspinat', 'g', 'obst_gemuese', V, [], [[125, 'Schale 125 g']], { shelfLifeDays: 3 }),
  I('tomate', 'Tomaten', 'g', 'obst_gemuese', V, [], [[500, 'Schale 500 g'], [1000, 'Beutel 1 kg']], { aliases: ['Tomate', 'Rispentomaten'], gramsPerPiece: 100, shelfLifeDays: 7 }),
  I('kirschtomaten', 'Kirschtomaten', 'g', 'obst_gemuese', V, [], [[250, 'Schale 250 g']], { aliases: ['Cherrytomaten', 'Cocktailtomaten'], gramsPerPiece: 15, shelfLifeDays: 6 }),
  I('gurke', 'Salatgurke', 'pcs', 'obst_gemuese', V, [], [[1, '1 Stück']], { aliases: ['Gurke'], gramsPerPiece: 400, shelfLifeDays: 7 }),
  I('paprika', 'Paprika', 'pcs', 'obst_gemuese', V, [], [[1, '1 Stück'], [3, 'Paprika-Mix 3 Stk']], { aliases: ['Paprikaschote', 'rote Paprika'], gramsPerPiece: 160, shelfLifeDays: 7 }),
  I('zucchini', 'Zucchini', 'pcs', 'obst_gemuese', V, [], [[1, '1 Stück']], { gramsPerPiece: 250, shelfLifeDays: 6 }),
  I('aubergine', 'Aubergine', 'pcs', 'obst_gemuese', V, [], [[1, '1 Stück']], { gramsPerPiece: 300, shelfLifeDays: 6 }),
  I('moehre', 'Möhren', 'g', 'obst_gemuese', V, [], [[500, 'Beutel 500 g'], [1000, 'Beutel 1 kg']], { aliases: ['Karotte', 'Karotten', 'Möhre', 'Mohrrübe'], gramsPerPiece: 80, shelfLifeDays: 14 }),
  I('kartoffel', 'Kartoffeln', 'g', 'obst_gemuese', V, [], [[1000, 'Netz 1 kg'], [2500, 'Sack 2,5 kg']], { aliases: ['Kartoffel', 'festkochende Kartoffeln'], gramsPerPiece: 120, shelfLifeDays: 30 }),
  I('suesskartoffel', 'Süßkartoffeln', 'g', 'obst_gemuese', V, [], [[500, 'Schale 500 g'], [1000, 'Beutel 1 kg']], { aliases: ['Süßkartoffel'], gramsPerPiece: 300, shelfLifeDays: 21 }),
  I('zwiebel', 'Zwiebeln', 'pcs', 'obst_gemuese', V, [], [[5, 'Netz 5 Stk (ca. 500 g)']], { aliases: ['Zwiebel', 'gelbe Zwiebel'], gramsPerPiece: 90, shelfLifeDays: 30 }),
  I('rote_zwiebel', 'Rote Zwiebeln', 'pcs', 'obst_gemuese', V, [], [[3, 'Netz 3 Stk']], { aliases: ['rote Zwiebel'], gramsPerPiece: 90, shelfLifeDays: 30 }),
  I('knoblauch', 'Knoblauch', 'pcs', 'obst_gemuese', V, [], [[10, '1 Knolle (ca. 10 Zehen)']], { aliases: ['Knoblauchzehe'], unitWeights: { Zehe: 1, Knolle: 10 }, gramsPerPiece: 5, shelfLifeDays: 30 }),
  I('ingwer', 'Ingwer', 'g', 'obst_gemuese', V, [], [[50, '1 Stück (ca. 50 g)']], { shelfLifeDays: 21 }),
  I('lauchzwiebeln', 'Lauchzwiebeln', 'pcs', 'obst_gemuese', V, [], [[6, '1 Bund (6 Stangen)']], { aliases: ['Frühlingszwiebeln'], unitWeights: { Bund: 6, Stange: 1 }, gramsPerPiece: 15, shelfLifeDays: 6 }),
  I('lauch', 'Lauch', 'pcs', 'obst_gemuese', V, [], [[1, '1 Stange']], { aliases: ['Porree'], gramsPerPiece: 250, shelfLifeDays: 10 }),
  I('brokkoli', 'Brokkoli', 'g', 'obst_gemuese', V, [], [[500, '1 Kopf (ca. 500 g)']], { unitWeights: { Kopf: 500 }, shelfLifeDays: 5 }),
  I('blumenkohl', 'Blumenkohl', 'g', 'obst_gemuese', V, [], [[800, '1 Kopf (ca. 800 g)']], { unitWeights: { Kopf: 800 }, shelfLifeDays: 6 }),
  I('champignons', 'Champignons', 'g', 'obst_gemuese', V, [], [[250, 'Schale 250 g'], [500, 'Schale 500 g']], { aliases: ['Pilze', 'Champignon'], shelfLifeDays: 5 }),
  I('spitzkohl', 'Spitzkohl', 'g', 'obst_gemuese', V, [], [[1000, '1 Kopf (ca. 1 kg)']], { unitWeights: { Kopf: 1000 }, shelfLifeDays: 10 }),
  I('kuerbis', 'Hokkaido-Kürbis', 'g', 'obst_gemuese', V, [], [[1200, '1 Kürbis (ca. 1,2 kg)']], { aliases: ['Kürbis', 'Hokkaido'], shelfLifeDays: 30 }),
  I('avocado', 'Avocado', 'pcs', 'obst_gemuese', V, [], [[1, '1 Stück'], [2, '2er-Netz']], { gramsPerPiece: 170, shelfLifeDays: 4 }),
  I('zitrone', 'Zitronen', 'pcs', 'obst_gemuese', V, [], [[1, '1 Stück']], { aliases: ['Zitrone'], gramsPerPiece: 100, shelfLifeDays: 21 }),
  I('limette', 'Limetten', 'pcs', 'obst_gemuese', V, [], [[1, '1 Stück']], { aliases: ['Limette'], gramsPerPiece: 60, shelfLifeDays: 14 }),
  I('apfel', 'Äpfel', 'pcs', 'obst_gemuese', V, [], [[1, '1 Stück']], { aliases: ['Apfel'], gramsPerPiece: 180, shelfLifeDays: 21 }),
  I('banane', 'Bananen', 'pcs', 'obst_gemuese', V, [], [[5, 'Bund 5 Stk']], { aliases: ['Banane'], gramsPerPiece: 120, shelfLifeDays: 5 }),
  I('heidelbeeren', 'Heidelbeeren', 'g', 'obst_gemuese', V, [], [[125, 'Schale 125 g']], { aliases: ['Blaubeeren', 'Beeren'], shelfLifeDays: 5 }),
  I('petersilie', 'Petersilie', 'pcs', 'obst_gemuese', V, [], [[1, '1 Bund']], { unitWeights: { Bund: 1, EL: 0.1 }, shelfLifeDays: 5 }),
  I('basilikum', 'Basilikum', 'pcs', 'obst_gemuese', V, [], [[1, '1 Topf']], { unitWeights: { Topf: 1, Handvoll: 0.3 }, shelfLifeDays: 7 }),
  I('koriander', 'Koriander', 'pcs', 'obst_gemuese', V, [], [[1, '1 Bund']], { unitWeights: { Bund: 1 }, shelfLifeDays: 5 }),
  I('schnittlauch', 'Schnittlauch', 'pcs', 'obst_gemuese', V, [], [[1, '1 Bund']], { unitWeights: { Bund: 1 }, shelfLifeDays: 5 }),
  I('dill', 'Dill', 'pcs', 'obst_gemuese', V, [], [[1, '1 Bund']], { unitWeights: { Bund: 1 }, shelfLifeDays: 5 }),
  I('rucola', 'Rucola', 'g', 'obst_gemuese', V, [], [[125, 'Schale 125 g']], { aliases: ['Rauke'], shelfLifeDays: 4 }),
  I('kopfsalat', 'Kopfsalat', 'pcs', 'obst_gemuese', V, [], [[1, '1 Kopf']], { aliases: ['Salat', 'Eisbergsalat'], gramsPerPiece: 400, shelfLifeDays: 5 }),

  // Brot & Backwaren
  I('brot', 'Vollkornbrot', 'g', 'brot_backwaren', V, ['gluten'], [[500, 'Laib 500 g']], { aliases: ['Brot', 'Sauerteigbrot'], unitWeights: { Scheibe: 50 }, shelfLifeDays: 5 }),
  I('toast', 'Toastbrot', 'g', 'brot_backwaren', VEG, ['gluten', 'milch'], [[500, 'Packung 500 g']], { unitWeights: { Scheibe: 25 }, shelfLifeDays: 7 }),
  I('broetchen', 'Brötchen', 'pcs', 'brot_backwaren', V, ['gluten'], [[1, '1 Stück'], [6, 'Aufbackbrötchen 6 Stk']], { aliases: ['Semmel'], gramsPerPiece: 60, shelfLifeDays: 2 }),
  I('tortillas', 'Weizen-Tortillas', 'pcs', 'brot_backwaren', V, ['gluten'], [[6, 'Packung 6 Stk'], [8, 'Packung 8 Stk']], { aliases: ['Wraps', 'Tortilla'], gramsPerPiece: 40, shelfLifeDays: 14 }),

  // Kühlregal
  I('sahne', 'Schlagsahne', 'ml', 'kuehlregal', VEG, ['milch'], [[200, 'Becher 200 ml']], { aliases: ['Sahne', 'Kochsahne'], densityGPerMl: 1, shelfLifeDays: 4 }),
  I('schmand', 'Schmand', 'g', 'kuehlregal', VEG, ['milch'], [[200, 'Becher 200 g']], { aliases: ['saure Sahne'], densityGPerMl: 1, shelfLifeDays: 5 }),
  I('creme_fraiche', 'Crème fraîche', 'g', 'kuehlregal', VEG, ['milch'], [[150, 'Becher 150 g']], { densityGPerMl: 1, shelfLifeDays: 5 }),
  I('milch', 'Milch', 'ml', 'kuehlregal', VEG, ['milch'], [[1000, 'Tüte 1 l']], { aliases: ['Vollmilch'], densityGPerMl: 1.03, shelfLifeDays: 6 }),
  I('butter', 'Butter', 'g', 'kuehlregal', VEG, ['milch'], [[250, 'Stück 250 g']], { densityGPerMl: 0.9, shelfLifeDays: 30 }),
  I('joghurt', 'Naturjoghurt', 'g', 'kuehlregal', VEG, ['milch'], [[150, 'Becher 150 g'], [500, 'Becher 500 g']], { aliases: ['Joghurt', 'griechischer Joghurt'], densityGPerMl: 1.05, shelfLifeDays: 7 }),
  I('skyr', 'Skyr', 'g', 'kuehlregal', VEG, ['milch'], [[450, 'Becher 450 g']], { densityGPerMl: 1.05, shelfLifeDays: 10 }),
  I('quark', 'Magerquark', 'g', 'kuehlregal', VEG, ['milch'], [[250, 'Becher 250 g'], [500, 'Becher 500 g']], { aliases: ['Quark'], densityGPerMl: 1.05, shelfLifeDays: 7 }),
  I('feta', 'Feta', 'g', 'kuehlregal', VEG, ['milch'], [[200, 'Packung 200 g']], { aliases: ['Schafskäse', 'Hirtenkäse'], shelfLifeDays: 7 }),
  I('mozzarella', 'Mozzarella', 'g', 'kuehlregal', VEG, ['milch'], [[125, 'Kugel 125 g']], { shelfLifeDays: 5 }),
  I('parmesan', 'Parmesan', 'g', 'kuehlregal', VEG, ['milch'], [[100, 'Stück 100 g'], [200, 'Stück 200 g']], { aliases: ['Grana Padano', 'Hartkäse'], densityGPerMl: 0.4, shelfLifeDays: 30 }),
  I('reibekaese', 'Geriebener Gouda', 'g', 'kuehlregal', VEG, ['milch'], [[200, 'Beutel 200 g']], { aliases: ['Reibekäse', 'Gouda', 'Käse gerieben'], shelfLifeDays: 14 }),
  I('halloumi', 'Halloumi', 'g', 'kuehlregal', VEG, ['milch'], [[250, 'Packung 250 g']], { aliases: ['Grillkäse'], shelfLifeDays: 30 }),
  I('frischkaese', 'Frischkäse', 'g', 'kuehlregal', VEG, ['milch'], [[200, 'Becher 200 g']], { densityGPerMl: 1, shelfLifeDays: 10 }),
  I('eier', 'Eier', 'pcs', 'kuehlregal', VEG, ['eier'], [[6, 'Packung 6 Stk'], [10, 'Packung 10 Stk']], { aliases: ['Ei', 'Eier Größe M'], gramsPerPiece: 60, shelfLifeDays: 21 }),
  I('tofu', 'Tofu natur', 'g', 'kuehlregal', V, ['soja'], [[200, 'Block 200 g'], [400, 'Block 400 g']], { aliases: ['Tofu'], shelfLifeDays: 10 }),
  I('gnocchi', 'Gnocchi', 'g', 'kuehlregal', V, ['gluten'], [[500, 'Packung 500 g']], { shelfLifeDays: 20 }),

  // Fleisch & Fisch
  I('haehnchenbrust', 'Hähnchenbrust', 'g', 'fleisch_fisch', MEAT, [], [[400, 'Packung 400 g'], [600, 'Packung 600 g']], { aliases: ['Hähnchen', 'Hühnerbrust', 'Hähnchenbrustfilet'], shelfLifeDays: 3 }),
  I('hackfleisch', 'Rinderhackfleisch', 'g', 'fleisch_fisch', MEAT, [], [[400, 'Packung 400 g'], [500, 'Packung 500 g']], { aliases: ['Hackfleisch', 'Hack', 'Rinderhack'], shelfLifeDays: 1 }),
  I('speck', 'Speckwürfel', 'g', 'fleisch_fisch', MEAT, [], [[150, 'Packung 2 × 75 g']], { aliases: ['Speck', 'Bacon'], shelfLifeDays: 14 }),
  I('schinken', 'Kochschinken', 'g', 'fleisch_fisch', MEAT, [], [[150, 'Packung 150 g']], { aliases: ['Schinken'], shelfLifeDays: 6 }),
  I('chorizo', 'Chorizo', 'g', 'fleisch_fisch', MEAT, [], [[100, 'Packung 100 g']], { shelfLifeDays: 20 }),
  I('lachs', 'Lachsfilet', 'g', 'fleisch_fisch', FISH, ['fisch'], [[250, 'Packung 2 Filets (250 g)']], { aliases: ['Lachs'], shelfLifeDays: 2 }),

  // Nudeln, Reis & Trockenes
  I('nudeln', 'Spaghetti', 'g', 'trockenwaren', V, ['gluten'], [[500, 'Packung 500 g']], { aliases: ['Nudeln', 'Pasta', 'Penne', 'Linguine'], shelfLifeDays: 365 }),
  I('reis', 'Reis', 'g', 'trockenwaren', V, [], [[500, 'Packung 500 g'], [1000, 'Packung 1 kg']], { aliases: ['Basmatireis', 'Risottoreis', 'Langkornreis'], shelfLifeDays: 365 }),
  I('linsen_rot', 'Rote Linsen', 'g', 'trockenwaren', V, [], [[500, 'Packung 500 g']], { aliases: ['Linsen'], shelfLifeDays: 365 }),
  I('couscous', 'Couscous', 'g', 'trockenwaren', V, ['gluten'], [[500, 'Packung 500 g']], { shelfLifeDays: 365 }),
  I('bulgur', 'Bulgur', 'g', 'trockenwaren', V, ['gluten'], [[500, 'Packung 500 g']], { shelfLifeDays: 365 }),
  I('haferflocken', 'Haferflocken', 'g', 'trockenwaren', V, ['gluten'], [[500, 'Packung 500 g']], { aliases: ['Hafer', 'Porridge-Haferflocken'], densityGPerMl: 0.4, shelfLifeDays: 365 }),
  I('muesli', 'Knuspermüsli', 'g', 'trockenwaren', V, ['gluten', 'schalenfruechte'], [[500, 'Packung 500 g']], { aliases: ['Müsli', 'Granola'], shelfLifeDays: 180 }),
  I('mehl', 'Weizenmehl', 'g', 'trockenwaren', V, ['gluten'], [[1000, 'Packung 1 kg']], { aliases: ['Mehl'], densityGPerMl: 0.55, shelfLifeDays: 365 }),
  I('reisnudeln', 'Reisnudeln', 'g', 'trockenwaren', V, [], [[250, 'Packung 250 g']], { aliases: ['Glasnudeln'], shelfLifeDays: 365 }),
  I('erdnussbutter', 'Erdnussbutter', 'g', 'trockenwaren', V, ['erdnuesse'], [[350, 'Glas 350 g']], { aliases: ['Erdnussmus'], densityGPerMl: 1.1, shelfLifeDays: 180 }),
  I('sesam', 'Sesam', 'g', 'trockenwaren', V, ['sesam'], [[100, 'Beutel 100 g']], { densityGPerMl: 0.6, shelfLifeDays: 365 }),
  I('cashews', 'Cashewkerne', 'g', 'trockenwaren', V, ['schalenfruechte'], [[200, 'Beutel 200 g']], { aliases: ['Cashews'], shelfLifeDays: 180 }),
  I('walnuesse', 'Walnusskerne', 'g', 'trockenwaren', V, ['schalenfruechte'], [[200, 'Beutel 200 g']], { aliases: ['Walnüsse'], shelfLifeDays: 180 }),
  I('honig', 'Honig', 'g', 'trockenwaren', VEG, [], [[250, 'Glas 250 g']], { densityGPerMl: 1.4, shelfLifeDays: 730 }),

  // Konserven & Gläser
  I('kokosmilch', 'Kokosmilch', 'ml', 'konserven', V, [], [[400, 'Dose 400 ml']], { unitWeights: { Dose: 400 }, densityGPerMl: 1, shelfLifeDays: 4 }),
  I('passierte_tomaten', 'Passierte Tomaten', 'g', 'konserven', V, [], [[500, 'Packung 500 g']], { aliases: ['Passata', 'Tomatenpassata'], densityGPerMl: 1.05, shelfLifeDays: 5 }),
  I('dosentomaten', 'Gehackte Tomaten (Dose)', 'g', 'konserven', V, [], [[400, 'Dose 400 g']], { aliases: ['Dosentomaten', 'stückige Tomaten', 'Tomaten aus der Dose'], unitWeights: { Dose: 400 }, densityGPerMl: 1.05, shelfLifeDays: 4 }),
  I('kichererbsen', 'Kichererbsen (Dose)', 'g', 'konserven', V, [], [[265, 'Dose 265 g abgetropft']], { aliases: ['Kichererbsen'], unitWeights: { Dose: 265 }, shelfLifeDays: 3 }),
  I('kidneybohnen', 'Kidneybohnen (Dose)', 'g', 'konserven', V, [], [[255, 'Dose 255 g abgetropft']], { aliases: ['Kidneybohnen', 'rote Bohnen'], unitWeights: { Dose: 255 }, shelfLifeDays: 3 }),
  I('mais', 'Mais (Dose)', 'g', 'konserven', V, [], [[285, 'Dose 285 g abgetropft']], { aliases: ['Mais', 'Zuckermais'], unitWeights: { Dose: 285 }, shelfLifeDays: 3 }),
  I('thunfisch', 'Thunfisch (Dose)', 'g', 'konserven', FISH, ['fisch'], [[150, 'Dose 150 g']], { aliases: ['Thunfisch'], unitWeights: { Dose: 150 }, shelfLifeDays: 2 }),
  I('tomatenmark', 'Tomatenmark', 'g', 'konserven', V, [], [[200, 'Tube 200 g']], { densityGPerMl: 1.1, shelfLifeDays: 30 }),
  I('pesto', 'Pesto Genovese', 'g', 'konserven', VEG, ['milch', 'schalenfruechte'], [[190, 'Glas 190 g']], { aliases: ['Pesto', 'Basilikumpesto'], densityGPerMl: 1, shelfLifeDays: 14 }),
  I('currypaste', 'Rote Currypaste', 'g', 'konserven', V, [], [[110, 'Glas 110 g']], { aliases: ['Currypaste'], densityGPerMl: 1, shelfLifeDays: 60 }),
  I('sojasauce', 'Sojasauce', 'ml', 'gewuerze_oele', V, ['soja', 'gluten'], [[150, 'Flasche 150 ml']], { aliases: ['Sojasoße', 'Shoyu'], densityGPerMl: 1.2, shelfLifeDays: 365 }),

  // Tiefkühl
  I('erbsen', 'Erbsen (TK)', 'g', 'tiefkuehl', V, [], [[450, 'Beutel 450 g']], { aliases: ['Erbsen', 'TK-Erbsen'], shelfLifeDays: 180 }),
  I('garnelen', 'Garnelen (TK)', 'g', 'tiefkuehl', FISH, ['krebstiere'], [[250, 'Packung 250 g']], { aliases: ['Garnelen', 'Shrimps', 'Crevetten'], shelfLifeDays: 180 }),

  // Süßes
  I('zartbitter', 'Zartbitterschokolade', 'g', 'suesses_snacks', VEG, ['milch', 'soja'], [[100, 'Tafel 100 g']], { aliases: ['Schokolade'], shelfLifeDays: 365 }),

  // Getränke
  I('hafermilch', 'Haferdrink', 'ml', 'getraenke', V, ['gluten'], [[1000, 'Packung 1 l']], { aliases: ['Hafermilch', 'Pflanzenmilch'], densityGPerMl: 1.02, shelfLifeDays: 5 }),

  // Gewürze & Öle (Vorrat vorausgesetzt)
  I('salz', 'Salz', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, densityGPerMl: 1.2 }),
  I('pfeffer', 'Pfeffer', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, densityGPerMl: 0.5 }),
  I('zucker', 'Zucker', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, densityGPerMl: 0.85 }),
  I('olivenoel', 'Olivenöl', 'ml', 'gewuerze_oele', V, [], [], { ...STAPLE, aliases: ['Öl'], densityGPerMl: 0.91 }),
  I('rapsoel', 'Rapsöl', 'ml', 'gewuerze_oele', V, [], [], { ...STAPLE, aliases: ['Pflanzenöl', 'Sonnenblumenöl'], densityGPerMl: 0.92 }),
  I('essig', 'Essig', 'ml', 'gewuerze_oele', V, ['sulfite'], [], { ...STAPLE, aliases: ['Balsamico', 'Weißweinessig'] }),
  I('senf', 'Senf', 'g', 'gewuerze_oele', V, ['senf'], [], { ...STAPLE, densityGPerMl: 1.05 }),
  I('gemuesebruehe', 'Gemüsebrühe', 'ml', 'gewuerze_oele', V, ['sellerie'], [], { ...STAPLE, aliases: ['Brühe', 'Gemüsefond'] }),
  I('paprikapulver', 'Paprikapulver', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, densityGPerMl: 0.45 }),
  I('kreuzkuemmel', 'Kreuzkümmel', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, aliases: ['Cumin'], densityGPerMl: 0.45 }),
  I('currypulver', 'Currypulver', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, aliases: ['Curry'], densityGPerMl: 0.45 }),
  I('oregano', 'Oregano', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, densityGPerMl: 0.2 }),
  I('chiliflocken', 'Chiliflocken', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, aliases: ['Chili'], densityGPerMl: 0.4 }),
  I('zimt', 'Zimt', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, densityGPerMl: 0.5 }),
  I('muskat', 'Muskatnuss', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, aliases: ['Muskat'], densityGPerMl: 0.5 }),
  I('backpulver', 'Backpulver', 'g', 'gewuerze_oele', V, [], [], { ...STAPLE, densityGPerMl: 0.9 }),
];
