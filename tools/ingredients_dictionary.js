/**
 * Known ingredient vocabulary for parsing the legacy Firebase data.
 *
 * The source strings are damaged (missing commas, typos), so instead of
 * trusting the text we look for known ingredients inside each fragment.
 * Longest names are matched first so "coconut milk" wins over "milk"
 * and "lemon juice" wins over "lemon".
 *
 * Grow these lists using:  node import_recipes.js --report
 */

// Common at-home items — never block a scan match.
const PANTRY = [
  // fats
  'sunflower oil','vegetable oil','cooking oil','sesame oil','mustard oil',
  'olive oil','coconut oil','peanut oil','groundnut oil','oil','ghee','butter',
  // sweet
  'sugar','brown sugar','jaggery','honey',
  // ground spices
  'turmeric powder','turmeric','red chilli powder','kashmiri red chilli powder',
  'kashmiri red chilli','chilli powder','coriander powder','cumin powder',
  'garam masala','chaat masala','pav bhaji masala','sambar powder','rasam powder',
  'amchur powder','amchur','dry mango powder','black pepper powder',
  // whole spices
  'mustard seeds','cumin seeds','coriander seeds','fennel seeds','poppy seeds',
  'nigella seeds','carom seeds','fenugreek seeds','sesame seeds','ajwain',
  'black peppercorns','peppercorns','black pepper','pepper','cinnamon stick',
  'cinnamon','cardamom','green cardamom','black cardamom','cloves','bay leaf',
  'bay leaves','star anise','nutmeg','mace','dry red chilli','dried red chilli',
  'asafoetida','hing','curry leaves','kasuri methi','dried fenugreek leaves',
  // basics
  'salt','black salt','water','vinegar','baking soda','baking powder',
  'corn flour','all purpose flour','maida','rice flour','oregano',
];

// Real ingredients that drive scan matching.
const CORE = [
  // vegetables
  'potato','potatoes','aloo','onion','onions','pearl onions','spring onion',
  'tomato','tomatoes','tomato puree','tomato paste','cauliflower florets',
  'cauliflower','cabbage','carrot','carrots','green peas','peas','capsicum',
  'bell pepper','brinjal','eggplant','okra','ladies finger','bhindi',
  'spinach','palak','methi leaves','fenugreek leaves','methi seeds','methi',
  'coriander leaves','fresh coriander','coriander','mint leaves','mint',
  'french beans','beans','drumstick','bottle gourd','ridge gourd','pumpkin',
  'radish','beetroot','sweet potato','raw banana','mushrooms','mushroom',
  'sweet corn','corn','broccoli','zucchini','cucumber','bitter gourd',
  'ash gourd','yam','colocasia','turnip',
  // aromatics / pastes
  'ginger garlic paste','ginger paste','garlic paste','green chilli paste',
  'garlic','ginger','green chillies','green chilli','red chillies','red chilli',
  // citrus / coconut
  'lemon juice','lime juice','lemon','lime','coconut milk','grated coconut',
  'fresh coconut','coconut','tamarind pulp','tamarind',
  // grains / pulses
  'basmati rice','cooked rice','rice','sooji','semolina','rava',
  'whole wheat flour','wheat flour','atta','besan','gram flour','poha','oats',
  'vermicelli','pasta','noodles','bread','toor dal','arhar dal','moong dal',
  'chana dal','urad dal','masoor dal','dal','rajma','chickpeas','kabuli chana',
  'chana','black eyed peas','sprouts','sabudana','quinoa',
  // dairy / protein
  'paneer','curd','yogurt','yoghurt','buttermilk','milk','condensed milk',
  'cream','fresh cream','malai','khoya','cheese','tofu',
  'eggs','egg','chicken','mutton','fish','prawns','shrimp',
  // fruit
  'mango','banana','apple','orange','pineapple','papaya','pomegranate',
  'grapes','watermelon','strawberry','dates','raisins','apricot',
  // nuts
  'cashew nuts','cashew','almonds','peanuts','walnuts','pistachios',
  // misc
  'soy sauce','tomato ketchup','chocolate','cocoa powder','vanilla',
];

// Fragments that are clearly not ingredients (prep words, stray text).
const JUNK = new Set([
  'to','taste','minutes','required','needed','as','and','or','for','the','a',
  'garnish','garnishing','tempering','optional','chopped','sliced','grated',
  'little','few','medium','large','small','cup','cups','tsp','tbsp','pinch',
  'handful','s','c','finely','finly','finaly','fresh','into','dry','cut',
  'whole','paste','leaves','green','black','white','yellow','red','raw',
  'slit','diced','soaked','roughly','cubes','cubed','cooking','thinly',
  'boiled','roasted','crushed','washed','grind','torn','ground','broken',
  'seasoning','gravy','homemade','ingredients','pods','powder','seeds',
  'peled','peeled','turmic','power','taspoon','turmon','clooves','sal',
  'masala','juice','flour','shredded','minced','halved','quartered','beaten',
  'strips','pieces','deseeded','stemmed','trimmed','drained','rinsed',
]);

module.exports = { PANTRY, CORE, JUNK };
