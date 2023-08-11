var ot = require ("./opentype.js");

(async () => {

  var font = await ot.load (process.argv[2]);

  var data = {
    cmap: font.tables.cmap.subtables.map (_ => ({glyphIndexMap:_.glyphIndexMap,encodingId:_.encodingID,platformID:_.platformID})),
    gsubFeatures: font.tables.gsub.features.map (_ => [_.tag, _.feature.lookupListIndexes]),
    gsubLookups: font.tables.gsub.lookups.map (_ => _.subtables),
  };
  
  process.stdout.write (JSON.stringify (data));

}) ();

/* License: Public Domain. */
