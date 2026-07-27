// GENERATED — do not edit by hand. See tools/gen_ingredient_assets.py
//
// Compile-time list of the ingredient drawings that actually ship. The widget
// checks this before calling SvgPicture.asset, because a missing asset throws
// at paint time rather than degrading — and with ~140 icon_keys in the database
// against 109 drawings, misses are the normal case, not the exception.

/// icon_key values with a specific drawing.
const kIngredientArt = <String>{
  'apple', 'bakingsoda', 'banana', 'banana_raw', 'bayleaf', 'besan',
  'broccoli', 'butter', 'buttermilk', 'cabbage', 'cardamom', 'cardamom_black',
  'carrot', 'cauliflower', 'cheese', 'chickpea', 'chickpea_black', 'chilli_green',
  'chilli_red', 'cinnamon', 'coconut', 'coconut_milk', 'colocasia', 'cream',
  'curd', 'dal', 'dal_arhar', 'dal_chana', 'dal_masoor', 'dal_moong',
  'dal_urad', 'drumstick', 'egg', 'flour', 'flour_corn', 'flour_rice',
  'garlic', 'ghee', 'ginger', 'honey', 'horsegram', 'jaggery',
  'khoya', 'leaves_coriander', 'leaves_curry', 'leaves_methi', 'leaves_mint', 'lemon',
  'lime', 'mango', 'milk', 'mushroom', 'oats', 'oil',
  'oil_coconut', 'oil_mustard', 'oil_olive', 'oil_sesame', 'oil_sunflower', 'onion',
  'orange', 'paneer', 'paste_chilli', 'paste_garlic', 'paste_gg', 'paste_ginger',
  'poha', 'potato', 'powder_amchur', 'powder_chaat', 'powder_chilli', 'powder_coriander',
  'powder_cumin', 'powder_garam', 'powder_hing', 'powder_pavbhaji', 'powder_pepper', 'powder_rasam',
  'powder_sambar', 'powder_turmeric', 'quinoa', 'radish', 'rajma', 'rice',
  'rice_basmati', 'salt', 'salt_black', 'seeds_ajwain', 'seeds_coriander', 'seeds_cumin',
  'seeds_fennel', 'seeds_methi', 'seeds_mustard', 'seeds_pepper', 'seeds_poppy', 'seeds_sesame',
  'sooji', 'soysauce', 'spinach', 'springonion', 'sprouts', 'sugar',
  'sweetpotato', 'tamarind', 'tofu', 'tomato', 'vinegar', 'water',
  'yam',
};

/// categories with a fallback drawing.
const kCategoryArt = <String>{
  'dairy', 'fruit', 'grain', 'herb', 'leafy', 'legume',
  'liquid', 'meat', 'nut', 'oil', 'other', 'seafood',
  'spice', 'sweetener', 'vegetable',
};
